#!/usr/bin/env sh

set -eu

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <tool-name> <dest-dir> <shared-dir> <specific-dir>" >&2
  exit 1
fi

tool_name=$1
dest_dir=$2
shared_dir=$3
specific_dir=$4

mkdir -p "$dest_dir"

names_file=$(mktemp)
map_file=$(mktemp)

cleanup() {
  rm -f "$names_file" "$map_file"
}

trap cleanup EXIT INT TERM

register_skills() {
  source_dir=$1
  source_label=$2

  if [ ! -d "$source_dir" ]; then
    return
  fi

  for skill_dir in "$source_dir"/*; do
    if [ ! -d "$skill_dir" ] || [ ! -f "$skill_dir/SKILL.md" ]; then
      continue
    fi

    skill_name=$(basename "$skill_dir")

    if grep -Fqx "$skill_name" "$names_file"; then
      echo "Error: duplicate skill '$skill_name' found while installing $tool_name skills." >&2
      echo "Conflicting source: $source_label ($skill_dir)" >&2
      exit 1
    fi

    printf '%s\n' "$skill_name" >> "$names_file"
    printf '%s\t%s\n' "$skill_name" "$skill_dir" >> "$map_file"
  done
}

register_skills "$shared_dir" "shared"
register_skills "$specific_dir" "$tool_name-specific"

for installed_path in "$dest_dir"/*; do
  if [ ! -L "$installed_path" ]; then
    continue
  fi

  installed_name=$(basename "$installed_path")

  if grep -Fqx "$installed_name" "$names_file"; then
    continue
  fi

  target_path=$(readlink "$installed_path" || true)

  case "$target_path" in
    "$shared_dir"/*|"$specific_dir"/*)
      rm "$installed_path"
      echo "  Removed stale skill: $installed_name"
      ;;
  esac
done

while IFS="$(printf '\t')" read -r skill_name skill_dir; do
  target="$dest_dir/$skill_name"

  if [ -L "$target" ]; then
    current_target=$(readlink "$target")

    if [ "$current_target" = "$skill_dir" ]; then
      continue
    fi

    rm "$target"
  elif [ -e "$target" ]; then
    echo "Error: refusing to replace non-symlink at $target" >&2
    exit 1
  fi

  ln -s "$skill_dir" "$target"
  echo "  Linked skill: $skill_name"
done < "$map_file"
