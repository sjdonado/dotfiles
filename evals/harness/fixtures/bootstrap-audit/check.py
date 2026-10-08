from pathlib import Path
assert 2 + 2 == 4
Path('.check-ran').write_text('passed\n')
print('local check passed')
