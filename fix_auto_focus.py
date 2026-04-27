import re

with open('lib/features/ui/game_screen.dart', 'r') as f:
    content = f.read()

# Remove _focusNode.requestFocus() inside the addPostFrameCallback in initState
# The code looks like:
#     WidgetsBinding.instance.addPostFrameCallback((_) {
#       if (!mounted) return;
#       _focusNode.requestFocus();
#       final currentNode =
#           ref.read(gameStateProvider).valueOrNull?.currentNode ?? 'intro_void';

content = re.sub(
    r"(_focusNode\.requestFocus\(\);\s*)(final currentNode =)",
    r"\2",
    content,
    count=1
)

with open('lib/features/ui/game_screen.dart', 'w') as f:
    f.write(content)
