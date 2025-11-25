# random-vscript
VScript scripts collection for various Source Engine games

Current tree:
```sh
├── cstrike
│   ├── map_veteran_achievement.nut # Automatically get 100 wins to get map veteran achievement
│   └── terror.nut                  # Terror-Strike: VScript Edition
└── works_in_multiple_games
    ├── dump_json_docs.nut       # Dump the VScript documentation as JSON
    ├── json_doc_to_mediawiki.js # Use the outputted JSON from dump_json_docs.nut to make a MediaWiki page
    ├── http_doc.nut             # Same as dump_json_docs.nut except it uses netcon to deliver the JSON dump
    └── http_doc_p2.nut          # Same as http_doc.nut but it works for Portal 2 engine branch
```

To use `dump_json_docs.nut` script located in works_in_multiple_games folder, do the following steps:
1. put the script in `your_game/scripts/vscripts`, **your_game** is the game folder name i.e. **cstrike**
2. launch the game
3. `sv_cheats 1;developer 1` in console
4. load into any map
5. make sure console is not receiving any unnecessary logs (this may intervene with dumping the documentation to JSON)
6. run `con_logfile json.log` in console
7. then `script_execute dump_json_docs.nut`
8. after its been ran successfully, run `con_logfile ""` to stop logging to a file
9. there should be a file named json.log in your game folder where gameinfo.txt is

For games like Nuclear Dawn you can use `http_doc.nut` instead to grab the JSON output from your HTTP client if -netconport is specified
