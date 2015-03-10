#!/usr/bin/env python

# All credits and glory go to https://code.google.com/p/crush-tools
# just keeping this python portable version handy for small inputs

import itertools
import os
import re
import sys


def reorder(instream, fields):
    for inline in instream:
        yield list(inline[f] for f in fields)

def add_field(instream, addspecs, header_aware):
    "Add fields to stream, fildspec is a list of (idx, value, header)"
    if header_aware:
        line = next(instream)
        for idx, _, hdr in addspecs:
            line.insert(idx, hdr)
        yield line
    for line in instream:
        for idx, val, _ in addspecs:
            line.insert(idx, val)
        yield line

def grepfield(instream, grepspec, header_aware, anyfield, icase, invert):
    flags = re.I if icase else 0
    regexes = tuple((idx, re.compile(pat, flags)) for idx, pat in grepspec)
    if header_aware:
        yield next(instream)
    fn = any if anyfield else all
    if invert:
        for line in instream:
            if fn(not regex.search(line[idx]) for idx, regex in regexes):
                yield line
    else:
        for line in instream:
            if fn(regex.search(line[idx]) for idx, regex in regexes):
                yield line

def calcfields(instream, calcspec, header_aware):
    if header_aware:
        line = next(instream)
        line.extend(header for _, header in calcspec)
        yield line
    for line in instream:
        line.extend(fn(*[line[i] for i in args]) for (fn, args), _ in calcspec)
        yield line


# output writers
def stream_writer(instream, delim, outstream):
    outstream.writelines(delim.join(l) + "\n" for l in instream)

def split_writer(instream, delim, fieldspec, header, bucket, outpath, outpat):
    ostreams, wrote_headers = {}, set()
    try:
        for line in instream:
            b = bucket(*tuple(line[arg] for arg in fieldspec))
            if b not in ostreams:
                filename = outpat.replace("%", b)
                outfile = os.path.join(outpath, filename)
                try:
                    ostreams[b] = open(outfile, "a")
                except IOError as e:
                    if e.errno != 24:
                        raise
                    for f in ostreams.itervalues():
                        f.close()
                    ostreams = {b: open(outfile, "a")}
                if header and b not in wrote_headers:
                    wrote_headers.add(b)
                    ostreams[b].write(delim.join(header) + "\n")
            ostreams[b].write(delim.join(line) + "\n")
    finally:
        for f in ostreams.itervalues():
            f.close()


# utils
def parse_keyspec(keyspec, header, delim):
    idxs, detected_header = [], False
    for spec in keyspec.split(","):
        if spec in header:
            idxs.append(header.index(spec))
            detected_header = True
        elif "-" in spec:
            start, _, end = spec.partition("-")
            start, end = int(start or 1), int(end or len(header))
            idxs.extend(range(start - 1, end))
        else:
            idxs.append(int(spec) - 1)
    assert all(k >= 0 and k < len(header) for k in idxs)
    return idxs, detected_header


# cmdline parsing
def main():
    import argparse
    gp = argparse.ArgumentParser()
    gp.add_argument("--delim", "-d", default=',')
    gp.add_argument("--no-header", "-N", action="store_true")
    sp = gp.add_subparsers(dest="command")

    p = sp.add_parser("reorder")
    p.add_argument("--fields", "-f", required=True)
    p.add_argument("infile", type=argparse.FileType('r'),
                   nargs="?", default=sys.stdin)

    p = sp.add_parser("addfield")
    p.add_argument("--idxs", "-i", required=True)
    p.add_argument("--values", "-v", required=True)
    p.add_argument("--headers", "-H")
    p.add_argument("infile", type=argparse.FileType('r'),
                   nargs="?", default=sys.stdin)

    p = sp.add_parser("grep")
    p.add_argument("--invert", "-v", action="store_true")
    p.add_argument("--icase", "-i", action="store_true")
    p.add_argument("--anyfield", "-a", action="store_true")
    p.add_argument("--fields", "-f", required=True)
    p.add_argument("patterns", nargs="+")
    p.add_argument("infile", type=argparse.FileType('r'),
                   nargs="?", default=sys.stdin)

    p = sp.add_parser("split")
    p.add_argument("--fields", "-f", required=True,
                   help="arguments to the partition function")
    p.add_argument("--bucket", "-b", default="lambda x: str(abs(hash(x)) % 10)",
                   help="Partition function, eg lambda x, y: x+y")
    p.add_argument("--path", "-p", default=".")
    p.add_argument("--copy-headers", "-H", action="store_true") # force headers
    p.add_argument("--outpat", "-o", default="%",
                   help="Output filename pattern, % is the bucket name")
    p.add_argument("infile", type=argparse.FileType('r'),
                   nargs="?", default=sys.stdin)

    p = sp.add_parser("calc")
    p.add_argument("--headers", "-H")
    p.add_argument("exprs", nargs="+")
    p.add_argument("infile", type=argparse.FileType('r'),
                   nargs="?", default=sys.stdin)


    args = gp.parse_args()
    out = None

    instream = (l.rstrip("\r\n").split(args.delim) for l in args.infile)
    firstline = next(instream)
    instream = itertools.chain([firstline], instream)

    # dealing with headers
    # a. no header
    # b.1. has header and treats it as such
    # b.2. has header but treats it as regular line

    if args.command == "reorder":
        fields, _ = parse_keyspec(args.fields, firstline, args.delim)
        out = reorder(instream, fields)

    elif args.command == "addfield":
        fields, detected_header = parse_keyspec(args.idxs, firstline, args.delim)
        header_aware = not args.no_header and (detected_header or args.headers)
        addheaders = args.headers.split(",") if args.headers else args.values
        addspec = zip(fields, args.values.split(","), addheaders.split(","))
        out = add_field(instream, addspec, header_aware or args.headers)

    elif args.command == "grep":
        fields, detected_header = parse_keyspec(args.fields, firstline, args.delim)
        header_aware = not args.no_header and detected_header
        assert len(fields) == len(args.patterns)
        grepspec = zip(fields, args.patterns)
        out = grepfield(instream, grepspec, header_aware,
                        args.anyfield, args.icase, args.invert)

    elif args.command == "split":
        fields, detected_header = parse_keyspec(args.fields, firstline, args.delim)
        header_aware = (not args.no_header and detected_header) or args.headers
        bucketfn = eval(args.bucket)
        header = next(instream) if header_aware else None
        split_writer(instream, args.delim, fields, header,
                     bucketfn, args.path, args.outpat)
        return # don't use default writer

    elif args.command == "calc":
        argre = re.compile("(\[[^\[\]]+\])")
        calcfuncs, detected_header = [], False
        for expr in args.exprs:
            fields = argre.findall(expr)
            # map field references to field indexes
            fieldspec = ",".join(f.strip("[]") for f in fields)
            fieldspec, detected_h = parse_keyspec(fieldspec, firstline, args.delim)
            detected_header |=  detected_h
            # make a variable for each referenced field
            varnames = ["_x%d" % i for i in fieldspec]
            # re-write expression to use variables
            for field, var in zip(fields, varnames):
                expr = expr.replace(field, var)
            # evaluate text into a function object
            expr = eval("lambda %s: %s" % (", ".join(varnames), expr))
            calcfuncs.append((expr, fieldspec))
        header_aware = not args.no_header and (detected_header or args.headers)
        exprheaders = args.headers.split(",") if args.headers else args.exprs
        calcspec = zip(calcfuncs, exprheaders)
        out = calcfields(instream, calcspec, header_aware)

    elif args.command == "uniq":
        pass
    elif args.command == "merge":
        pass
    elif args.command == "sample":
        pass
    elif args.command == "convdate":
        pass

    stream_writer(out, args.delim, sys.stdout)


if __name__ == "__main__":
    sys.exit(main())
