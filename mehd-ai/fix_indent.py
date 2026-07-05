filepath = 'backend/auto_execution_worker.py'
with open(filepath, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Line numbers are 1-indexed, so 816 is index 815
for i in range(815, 938):
    if lines[i].startswith('    '):
        lines[i] = lines[i][4:]

with open(filepath, 'w', encoding='utf-8') as f:
    f.writelines(lines)
print("Indentation fixed.")
