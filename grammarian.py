import argparse
import string
import sys

_LETTERS = string.ascii_lowercase
_WORDS = set(w.lower().strip() for w in open("words.txt").readlines())


def single_letter_changes_for_word(word: str, allow_remove=False, allow_add=False):
    word = word.lower()
    for i in range(len(word)):
        if allow_remove:
            yield word[:i] + word[i + 1 :]

        for l in _LETTERS:
            if word[i] != l:
                # Replace a letter
                yield word[:i] + l + word[i + 1 :]
                if allow_add:
                    yield word[:i] + l + word[i:]


def single_letter_changes_for_text(text: str):
    words = [w.lower() for w in text.split(" ")]
    for i, word in enumerate(words):
        for word_variation in single_letter_changes_for_word(word):
            yield " ".join(words[:i] + [word_variation] + words[i+1:])


def spell_variations(name: str):
    for variation in single_letter_changes_for_text(name):
        if set(variation.split(" ")) <= _WORDS:
            yield variation

def main():
    parser = argparse.ArgumentParser(description="What the program does")
    parser.add_argument("-n", "--name")
    args = parser.parse_args()

    for variation in spell_variations(args.name):
        print(variation)


if __name__ == "__main__":
    main()
