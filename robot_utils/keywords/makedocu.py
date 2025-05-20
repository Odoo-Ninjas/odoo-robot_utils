from pathlib import Path
import inspect
import os
from pathlib import Path

current_dir = Path(
    os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
)


def generate_markdown_from_keywords(input_file):
    # Parse the Robot Framework file

    passed_keywords = False
    for line in input_file.read_text().splitlines():
        if "*** Keywords ***" in line:
            passed_keywords = True
            continue
        if not passed_keywords:
            continue
        if any(line.startswith(x) for x in "\t "):
            continue
        if line.startswith("#"):
            continue
        func = line.split("[Arguments]")[0].strip()
        if not func:
            continue
        yield input_file, func


# Input and output paths
os.chdir(current_dir)
content = {}
output_file = Path("documentation.md")
for path in sorted(Path(".").glob("*.robot")):
    input_file = path
    for line in generate_markdown_from_keywords(input_file):
        key = line[0].name
        content.setdefault(key, [f"# {line[0].name}"])
        content[key].append(f"  * {line[1]}")

strcontent = []
for key, values in content.items():
    strcontent += [values[0]] + list(sorted(values[1:]))
output_file.write_text("\n".join(strcontent))
