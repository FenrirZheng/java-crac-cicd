#!/usr/bin/zsh
rsync -avz --exclude 'checkpoint'  --exclude 'rsync.sh'  ./  CMS-Sit-02:/root/mng-deploy
