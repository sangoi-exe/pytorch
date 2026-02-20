from __future__ import annotations

import argparse
import os
import re
import subprocess
from pathlib import Path

from setuptools import distutils  # type: ignore[import,attr-defined]


UNKNOWN = "Unknown"
RELEASE_PATTERN = re.compile(r"/v[0-9]+(\.[0-9]+)*(-rc[0-9]+)?/")


def _normalize_cuda_arch_list(raw_arch_list: str) -> list[str]:
    arch_tokens: list[str] = []
    seen_tokens: set[str] = set()
    for raw_token in re.split(r"[,\s;]+", raw_arch_list):
        token = raw_token.strip()
        if not token:
            continue
        token = token.lower()
        token = token.replace("+ptx", "")
        token = token.replace("sm_", "")
        token = token.replace("compute_", "")
        token = token.replace(".", "")
        if not token or not token.isdigit():
            continue

        normalized_token = f"sm{token}"
        if normalized_token in seen_tokens:
            continue
        seen_tokens.add(normalized_token)
        arch_tokens.append(normalized_token)
    return arch_tokens


def _extract_cuda_tag(raw_value: str) -> str | None:
    token = raw_value.strip().lower()
    if not token:
        return None

    direct_match = re.fullmatch(r"cu(\d{2,4})", token)
    if direct_match is not None:
        return f"cu{direct_match.group(1)}"

    semver_match = re.search(r"(\d+)\.(\d+)", token)
    if semver_match is not None:
        major = int(semver_match.group(1))
        minor = int(semver_match.group(2))
        return f"cu{major}{minor}"

    compact_match = re.search(r"\b(\d{2,4})\b", token)
    if compact_match is not None:
        return f"cu{compact_match.group(1)}"

    return None


def _resolve_cuda_tag() -> str | None:
    explicit = _extract_cuda_tag(os.getenv("PYTORCH_CUDA_VERSION_TAG", ""))
    if explicit is not None:
        return explicit

    for env_name in ("CUDA_VERSION", "DESIRED_CUDA"):
        parsed = _extract_cuda_tag(os.getenv(env_name, ""))
        if parsed is not None:
            return parsed

    for env_name in ("CUDA_PATH", "CUDA_HOME", "CUDAToolkit_ROOT"):
        parsed = _extract_cuda_tag(os.getenv(env_name, ""))
        if parsed is not None:
            return parsed

    return None


def _strip_prerelease_suffix(version: str) -> str:
    base = version.split("+", 1)[0]
    prerelease_removed = re.sub(r"(a|b|rc)\d+$", "", base)
    return prerelease_removed or base


def _append_cuda_arch_suffix(version: str) -> str:
    raw_arch_list = os.getenv("TORCH_CUDA_ARCH_LIST", "").strip()
    if not raw_arch_list:
        return version

    arch_tokens = _normalize_cuda_arch_list(raw_arch_list)
    if not arch_tokens:
        return version

    version_base = _strip_prerelease_suffix(version)
    local_parts: list[str] = []
    cuda_tag = _resolve_cuda_tag()
    if cuda_tag is not None:
        local_parts.append(cuda_tag)
    local_parts.extend(arch_tokens)

    if not local_parts:
        return version_base

    suffix = ".".join(local_parts)
    return f"{version_base}+{suffix}"


def get_sha(pytorch_root: str | Path) -> str:
    try:
        rev = None
        if os.path.exists(os.path.join(pytorch_root, ".git")):
            rev = subprocess.check_output(
                ["git", "rev-parse", "HEAD"], cwd=pytorch_root
            )
        elif os.path.exists(os.path.join(pytorch_root, ".hg")):
            rev = subprocess.check_output(
                ["hg", "identify", "-r", "."], cwd=pytorch_root
            )
        if rev:
            return rev.decode("ascii").strip()
    except Exception:
        pass
    return UNKNOWN


def get_tag(pytorch_root: str | Path) -> str:
    try:
        tag = subprocess.run(
            ["git", "describe", "--tags", "--exact"],
            cwd=pytorch_root,
            encoding="ascii",
            capture_output=True,
        ).stdout.strip()
        if RELEASE_PATTERN.match(tag):
            return tag
        else:
            return UNKNOWN
    except Exception:
        return UNKNOWN


def get_torch_version(sha: str | None = None) -> str:
    pytorch_root = Path(__file__).absolute().parent.parent
    version = open(pytorch_root / "version.txt").read().strip()

    if os.getenv("PYTORCH_BUILD_VERSION"):
        assert os.getenv("PYTORCH_BUILD_NUMBER") is not None
        build_number = int(os.getenv("PYTORCH_BUILD_NUMBER", ""))
        version = os.getenv("PYTORCH_BUILD_VERSION", "")
        if build_number > 1:
            version += ".post" + str(build_number)
        return version
    elif sha != UNKNOWN:
        if sha is None:
            sha = get_sha(pytorch_root)
        version += "+git" + sha[:7]

    return _append_cuda_arch_suffix(version)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate torch/version.py from build and environment metadata."
    )
    parser.add_argument(
        "--is-debug",
        "--is_debug",
        type=distutils.util.strtobool,
        help="Whether this build is debug mode or not.",
    )
    parser.add_argument("--cuda-version", "--cuda_version", type=str)
    parser.add_argument("--hip-version", "--hip_version", type=str)
    parser.add_argument("--xpu-version", "--xpu_version", type=str)

    args = parser.parse_args()

    assert args.is_debug is not None
    args.cuda_version = None if args.cuda_version == "" else args.cuda_version
    args.hip_version = None if args.hip_version == "" else args.hip_version
    args.xpu_version = None if args.xpu_version == "" else args.xpu_version

    pytorch_root = Path(__file__).parent.parent
    version_path = pytorch_root / "torch" / "version.py"
    # Attempt to get tag first, fall back to sha if a tag was not found
    tagged_version = get_tag(pytorch_root)
    sha = get_sha(pytorch_root)
    if tagged_version == UNKNOWN:
        version = get_torch_version(sha)
    else:
        version = tagged_version

    with open(version_path, "w") as f:
        f.write("from typing import Optional\n\n")
        f.write(
            "__all__ = ['__version__', 'debug', 'cuda', 'git_version', 'hip', 'xpu']\n"
        )
        f.write(f"__version__ = '{version}'\n")
        # NB: This is not 100% accurate, because you could have built the
        # library code with DEBUG, but csrc without DEBUG (in which case
        # this would claim to be a release build when it's not.)
        f.write(f"debug = {repr(bool(args.is_debug))}\n")
        f.write(f"cuda: Optional[str] = {repr(args.cuda_version)}\n")
        f.write(f"git_version = {repr(sha)}\n")
        f.write(f"hip: Optional[str] = {repr(args.hip_version)}\n")
        f.write(f"xpu: Optional[str] = {repr(args.xpu_version)}\n")
