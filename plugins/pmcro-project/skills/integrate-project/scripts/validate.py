from __future__ import annotations
import argparse,json,tempfile,subprocess,sys
from pathlib import Path

def main():
    root=Path(__file__).resolve().parents[1]
    for rel in ['SKILL.md','agents','scripts','references','assets','tests']:
        p=root/rel
        if not p.exists():raise SystemExit(f'missing {rel}')
    print('PASS')
if __name__=='__main__':main()
