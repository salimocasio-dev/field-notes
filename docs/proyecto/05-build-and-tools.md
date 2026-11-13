# What is built, and the working facts (copy of the project page, Nov 13)

For what was built after story 1, page 08 wins.

## The old test page

- Live: https://salimocasio-dev.github.io/field-notes/ (one file, index.html at the repo root).
- A map, the Casa and Parque scenes, a live call with Danny, touch answers, a record per word. Built before the reviewed plan; its rules (fixed returns after 1, 3, 7, 14, 30 days; steps by number of hearings) are replaced by the plan.
- Its progress is stored in the browser under coqui.v3. Do not wipe it.

**How the page and Danny talk**

- The page sends: place, scene, words (one line per word: word | picture key = note | touch or say | step N | NEW or DUE), opening, minutes.
- Messages from the page to Danny: "(toca: X. Correct.)", "(toca: X. Wrong: you asked for Y.)", "(ayuda)", "(fin)", "PASO: «X» is now step N."
- Danny has one tool: show_picture (a picture key, or "todo" for the whole scene).
- The call must use connectionType "websocket". Over WebRTC the page is refused by the agent's allowlist.
- The touch timer starts when Danny stops talking. A touch made before he finishes asking is never a miss.

## Story 1 as first built (La lluvia)

- Salim said "Build story one" after reading page 06. Built to draft 3. Karina (es-PR-KarinaNeural), 12% under her normal pace.
- Earlier versions: version 1 spoke in bare labels with long pauses ("beyond boring"); version 2 followed his sketch ("much better") and had no stakes.
- Why a right touch on the door "read as wrong" in version 1 (Claude's best account): the door was marked before a touch on it counted, so a touch only shook the screen with a low thud. In the game, the sign and the moment a touch counts are the same.

## The audio job

- .github/workflows/voz.yml and historia/tools/voz.py. Needs one secret: AZURE_SPEECH_KEY (region eastus written in the job).
- Starts by itself when a file in historia/cuentos/ changes (story mode). Can be started by hand from the Actions tab ("Voz").
- Mode "muestras": every Spanish voice Azure has reads the same six lines into historia/muestras/ (96 voices, 53 women, 43 men, 22 places; both Puerto Rican voices). One run uses about 9,500 characters. https://salimocasio-dev.github.io/field-notes/historia/muestras/
- Mode "cuento": every clip of every story file, in the chosen voices, to historia/audio/. A clip whose text, voice and pace have not changed is not made again. The page plays the clips listed in historia/audio/ready.json.
- Voices: narrator Karina; the coquí (who "tu") Victor (es-PR-VictorNeural, default since Nov 13).
- The job waits 3.2 seconds between lines, on the belief that the free tier allows 20 requests a minute. From memory, not checked.
- Azure addresses checked Nov 13: https://{region}.tts.speech.microsoft.com/cognitiveservices/v1 and /cognitiveservices/voices/list, key in the Ocp-Apim-Subscription-Key header.
- Azure: Salim's free account; subscription "Azure subscription 1" in Default Directory (if the portal shows none, switch directory under Settings, Directories). Resource coqui-voz-2611, resource group coqui, East US, Free F0. He pasted KEY 1 into the GitHub secret.
- The workspace cannot reach Azure; GitHub can. That is why the job runs there.

## Recorded audio: decided Nov 13

- The recorded stories do not use ElevenLabs ("11 is overkill for this"). Each line is made once and saved as a file. Not on demand.
- Size (estimate, not measured): about 1 million characters for all of A1 (0.8 to 1.4 million).
- Azure price (looked up Nov 13; check again before spending): first 500,000 characters a month free; after that $15 per 1 million characters. The free tier stops at the limit; it cannot bill.
- Other options he was shown: ElevenLabs about $165 for A1 (kept for live calls); Gemini TTS about $45; OpenAI gpt-4o-mini-tts about $50; open models free but need a graphics card.

## Danny, the live agent (ElevenLabs)

- Name: "Coquí – Danny v2". Id: agent_3301m795q3xtfpx8c99zc0s870vm. Branch: agtbrch_0001m795q3y6e9yreeg7z9tkdccq.
- Model: claude-sonnet-5-5, temperature 0.3, thinking off (reply delay about 2 s).
- Voice: Danny-Boricua, kcsUqKsJMPz7j3H6QPNd. Speed 0.85, stability 0.85, expressive mode off. About 2.7 syllables a second with pauses.
- Turns: patient, 15-second timeout. First message comes from the page.
- Prompt version agtvrsn_4101m798pc0ke708dfpdjyb3cf7x. Turn settings version agtvrsn_4301m798pf9bftvtkc4e47dev3ja.
- Locked to the test page: allowlist salimocasio-dev.github.io, origin required, 15 calls a day, 2 at once. Removing the allowlist was refused as a security change. His decision. Do not work around it.
- The older agent, agent_6401m78ayjywf3rbjdpbtfzxr259, is locked and unused.
- Known small flaw: after the hola exchange Danny sometimes asks "Toca la abuela" twice in a row.
- Not yet done for the new plan: its brief needs the list of words open for speaking, and the place's job.
- Tests attached: touches test_2901m795v4cve0vrytfz7s13be9w; confused test_6801m795v4w4ea0rbzn67gr6edgs; silent test_9401m795v5b8f6yad1aq0a95jpda; speaks test_9601m795v5rwf4n9gnkfkts5ermp (inconclusive); day two test_9401m79704g6f4trp3mgxq1kn7mz. Last full run: confused passed, silent passed, touches 6 of 7, day two 5 of 6.
- Testing the page with the real call code: in his desktop Chrome on the live page, replace the microphone with a silent stream, start the call with real clicks, drive touches with Mission.tap. Save localStorage["coqui.v3"] before and put it back after.

## ElevenLabs costs (measured)

- A live call costs about 650 credits a minute, about $6.50 an hour at $1.65 per 10,000 credits.
- One 5-minute call a day is about 100,000 credits a month. A simulated test costs 500 to 1,400 credits.
- Nov 12: the month's allowance (633,357 credits, Pro plan) was fully used; it renews Nov 16. Check the balance before any call or test, and tell Salim the amount first.

## The word-list check

- The 477 draft words were checked against the hermitdave FrequencyWords list (es_50k). Results in 01-plan, "The word list". The list is public and the check can be run again.

## Limits

- Claude may not type passwords, keys or card details. Salim does that.
- Creating an account or a paid resource needs his clear yes first. Any spend needs the amount confirmed with him first.
- Downloading a file needs his yes. His email address is private.
