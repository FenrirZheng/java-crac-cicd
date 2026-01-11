#!/usr/bin/zsh
rsync -avz --exclude 'checkpoint'  --exclude 'rsync.sh'  ./deploy/  CMS-Sit-02:/root/deploy-mng/deploy/
rsync -avz --exclude 'checkpoint'  --exclude 'rsync.sh'  ./new-deploy.sh  CMS-Sit-02:/root/deploy-mng/new-deploy.sh
