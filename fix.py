import re

with open('c:/Users/krmta/OneDrive/Desktop/pndtbcknd/frontend/pandit_ssetu/lib/screens/shop_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# We know that the code looks like:
#   }
#     {
#       'id': 901,
#       'name': 'Satyanarayan Katha Complete Kit',
# ...
#   ];
# 
# We need to remove from that '{' all the way down to '];' and replace it with just '  // dynamic products loaded here' or empty.

# First let's find the `  }\n    {` which is where my replacement went wrong.
start_idx = content.find('  }\n    {\n      \'id\': 901,')
if start_idx != -1:
    end_idx = content.find('];', start_idx)
    if end_idx != -1:
        new_content = content[:start_idx + 3] + content[end_idx + 2:]
        with open('c:/Users/krmta/OneDrive/Desktop/pndtbcknd/frontend/pandit_ssetu/lib/screens/shop_screen.dart', 'w', encoding='utf-8') as f:
            f.write(new_content)
        print("Fixed shop_screen.dart!")
    else:
        print("Could not find ];")
else:
    print("Could not find start_idx")
