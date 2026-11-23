#!/usr/bin/env python3
"""merge_lists.py SCENE : in the current worktree, resolve the conflicts of `git merge main` in the shared lists:
each hunk becomes main's lines, then the branch's lines main lacks (a line equal but for a trailing ',' or ' ||'
is taken once, in the branch's spelling when the branch goes on after it). Comment hunks: main's, with SCENE added."""
import re,subprocess,sys
X=sys.argv[1]
files=subprocess.run(['git','diff','--name-only','--diff-filter=U'],capture_output=True,text=True).stdout.split()
pat=re.compile(r'<<<<<<< HEAD\n(.*?)=======\n(.*?)>>>>>>> main\n',re.S)
norm=lambda l: re.sub(r'(,| \|\|)\s*$','',l.rstrip())
for f in files:
    if f.endswith('fixtures/sheets.dart') or f.endswith('pp/index.json'):
        subprocess.run(['git','checkout','--theirs',f]); print('theirs (remake by its tool):',f); continue
    t=open(f,encoding='utf-8').read()
    def rep(m):
        ours=m.group(1).split('\n')[:-1]; theirs=m.group(2).split('\n')[:-1]
        if ours and theirs and all(l.lstrip().startswith('//') for l in ours+theirs):
            s='\n'.join(theirs)+'\n'
            s=re.sub(r'\|esquina\]', '|esquina|%s]'%X, s) if '|%s]'%X not in s else s
            s=re.sub(r'caja or esquina\)', 'caja, esquina or %s)'%X, s)
            return s
        tn=[norm(l) for l in theirs]; out=list(theirs)
        for i,l in enumerate(ours):
            n=norm(l)
            if n in tn:
                j=tn.index(n)
                if l!=theirs[j] and i<len(ours)-1: out[out.index(theirs[j])]=l   # the branch goes on after it
                continue
            if not any(norm(x) not in tn for x in ours[:i]) and i>0 and out:   # the first line of the branch's own
                m2=re.search(r'(,| \|\|)\s*$',ours[i-1])
                if m2 and not re.search(r'(,| \|\|)\s*$',out[-1]) and out[-1].strip(): out[-1]=out[-1].rstrip()+m2.group(1)
            if out and out[-1].strip():
                last=out[-1].rstrip(); s=l.strip()
                if re.search(r"id == '\w+'$",last) and s.startswith('id =='): out[-1]=last+' ||'
                elif last.endswith('}') and s.startswith('{'): out[-1]=last+','
                elif re.match(r"'\w+': \($",s) and not last.endswith(('),','{')): out.append(re.match(r'\s*',l).group(0)+'),')
            out.append(l)
        return '\n'.join(out)+('\n' if out else '')
    t2,n=pat.subn(rep,t); open(f,'w',encoding='utf-8').write(t2); print(n,'hunks:',f)
