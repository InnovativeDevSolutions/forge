@echo off
cd /d "%~dp0"
surreal start --user root --pass root --bind 127.0.0.1:8000 rocksdb://forge.db
