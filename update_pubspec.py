with open("pubspec.yaml", "r") as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    new_lines.append(line)
    if "dependencies:" in line:
        new_lines.append("  google_mlkit_image_labeling: ^0.12.0\n")
        new_lines.append("  path_provider: ^2.1.1\n")

with open("pubspec.yaml", "w") as f:
    f.writelines(new_lines)
