# Issue #17 / PR #77: the six real-app plays of La plaza, `TXT=no`

What this is: `coqui/app/tool/gate_a_frames_test.dart` plays each of the three stories of La plaza twice in the real app shell
(the app on the harness's fakes: silent clips, the scripted recogniser, the fake clock; 390 x 844 screen at ratio 2, the real
fonts), once with every answer right (`right`) and once with every answer wrong first (`wrong`). `TXT=no` means the story's
words never show: what you see is only what a learner sees with the words off. The only text on a picture is the app's own
end screen (the story's title and its buttons).

Made on branch `story/17`, commit `b03bee9f` (main merged in), Flutter 3.50.0, with:

    python3 coqui/tool/make_previa.py --places colmado,calle,plaza --allow-missing-scenes
    cd coqui/app && flutter test tool/gate_a_frames_test.dart \
        --dart-define=STORIES=mucho-gusto,de-donde-eres,hablo-espanol \
        --dart-define=TXT=no --dart-define=OUT=<dir>

and `coqui/app/assets/previa/` put back as it was after the plays (`git status` clean, nothing under `historia/` changed).

| play | pictures | contact sheets | reached the end | stopped | touches | story time |
| --- | ---: | ---: | --- | --- | ---: | ---: |
| mucho-gusto-right | 13 | 4 | yes | null | 6 | 113.2 s |
| mucho-gusto-wrong | 21 | 6 | yes | null | 11 | 131.4 s |
| de-donde-eres-right | 13 | 4 | yes | null | 6 | 116.0 s |
| de-donde-eres-wrong | 21 | 6 | yes | null | 11 | 129.5 s |
| hablo-espanol-right | 10 | 3 | yes | null | 4 | 147.4 s |
| hablo-espanol-wrong | 13 | 4 | yes | null | 7 | 152.1 s |
| **all six** | **91** | **27** | **6 of 6** | | | |

Each folder holds `sheet-NN.png` (the contact sheets: start, each tap, each ask, the end, in order), the pictures
`NN-<kind>.png` they are made from (780 x 1688), and `index.json` (what each picture is). `summary.json` has the numbers above.
