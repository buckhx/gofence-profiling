import argparse
from glob import glob
import json
import os.path
import sys


def shuffle_cat(path, count):
    """Cat the contents of files match path and shuffle by line"""
    files = [open(f) for f in glob(path)]
    try:
        colls = [json.load(f)["features"] for f in files]
        features = reduce(lambda x, y: x+y, colls)
        for i in xrange(count):
            cur = features[i % len(features)]
            print json.dumps(cur)
    finally:
        for f in files:
            f.close()

parser = argparse.ArgumentParser(description='Cat files matching the pattern')
parser.add_argument('-p', help='path pattern to match', default='./*feed.geojson')
parser.add_argument('-n', type=int, default=100000,
                    help='number of output lines, loops files until satisfied')


if __name__ == "__main__":
    args = parser.parse_args()
    shuffle_cat(args.p, args.n)
