# -*- coding: utf-8 -*-
import os
import re
import sys

if not "PROMPT" in os.environ:
    nullfile = open(os.devnull, "w")
    sys.stdout = nullfile
    sys.stderr = nullfile

from glue_qt.main import main

if __name__ == "__main__":
    sys.argv[0] = re.sub(r"(-script\.pyw?|\.exe)?$", "", sys.argv[0])
    sys.exit(main())
