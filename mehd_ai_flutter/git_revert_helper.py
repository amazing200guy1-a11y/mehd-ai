import subprocess

def get_commits(filepath):
    out = subprocess.check_output(['git', 'log', '--oneline', filepath])
    print(f"commits for {filepath}:")
    print(out.decode())

try:
    get_commits('lib/screens/onboarding_screen.dart')
    get_commits('lib/screens/home_screen.dart')
    get_commits('lib/screens/onboarding/welcome_screen.dart')
except Exception as e:
    print(f"Error: {e}")
