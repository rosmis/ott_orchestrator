#  _____          _        _ _
# |_   _|        | |      | | |
#   | | _ __  ___| |_ __ _| | |
#   | || '_ \/ __| __/ _` | | |
#  _| || | | \__ \ || (_| | | |
#  \___/_| |_|___/\__\__,_|_|_|

.PHONY: clone-all
clone-all:  ## delete all current repositories and clone both repos on main
	$(call printSection,CLONE ALL)
	rm -rf wedotv_ott_front
	git clone https://github.com/rosmis/ott_front.git wedotv_ott_front
	rm -rf wedotv_ott_back
	git clone https://github.com/rosmis/ott_back.git wedotv_ott_back
	cp wedotv_ott_front/.env.example wedotv_ott_front/.env
	cp wedotv_ott_back/.env.example wedotv_ott_back/.env
	docker compose up -d --build
	cd wedotv_ott_front && npm install && npm run dev