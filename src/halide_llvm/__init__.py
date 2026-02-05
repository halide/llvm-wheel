from importlib.metadata import version

__version__ = version("halide-llvm")


def main():
    print(f"halide-llvm version: {__version__}")


if __name__ == "__main__":
    main()
