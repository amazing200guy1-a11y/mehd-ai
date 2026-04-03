import os
import re

def find_setstate_in_build(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()

                # Find all build methods
                build_pattern = re.compile(r'(Widget\s+build\s*\(BuildContext\s+[^)]+\)\s*{)(.*?)(^\s*}$)', re.MULTILINE | re.DOTALL)
                
                # We can also just simply look for any build method bracket matching but nested brackets make regex hard.
                # Let's do simple line by line check
                in_build = False
                bracket_count = 0
                lines = content.split('\n')
                for i, line in enumerate(lines):
                    if re.search(r'Widget\s+build\s*\(BuildContext\s+', line):
                        in_build = True
                        bracket_count = line.count('{') - line.count('}')
                        continue
                    
                    if in_build:
                        bracket_count += line.count('{') - line.count('}')
                        if 'setState(' in line:
                            print(f"{filepath}:{i+1}: {line.strip()}")
                        if bracket_count <= 0:
                            in_build = False

if __name__ == '__main__':
    find_setstate_in_build(r'c:\Mehd ai\mehd_ai_flutter\lib')
