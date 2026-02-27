# AGENTS.md

This file defines the required workflow for any AI agent working in this repository.

## Project Goal

- Maintain and publish the static personal site for `longwei.org.cn` and `www.longwei.org.cn`.
- Source files live in this repo root (for example `index.html`, image assets).

## Deployment Architecture

- Static hosting: Alibaba Cloud OSS bucket (private)
  - Bucket: `longwei-org-cn-site-20260226205642`
  - Region: `cn-hongkong`
- Delivery: Alibaba Cloud CDN
  - Domains: `www.longwei.org.cn`, `longwei.org.cn`
  - Region (API): `cn-hangzhou`
- HTTPS: Let's Encrypt (acme.sh) + upload to CDN

## Required Files

- Deploy env file: `~/.config/longwei-site/deploy.env`
- Scripts:
  - `scripts/setup-site-env.sh`
  - `scripts/deploy-site.sh`
  - `scripts/push-cert-to-cdn.sh`
  - `scripts/install-acme-hook.sh`
  - `scripts/build-macos-publish-app.sh`

## Standard Update Workflow (for any AI)

1. Edit site files in repo root.
2. Run deploy:
   - `cd ~/longwei-dev && ./scripts/deploy-site.sh`
3. Verify:
   - `curl -I https://www.longwei.org.cn/`
   - `curl -I https://longwei.org.cn/`
   - both should return `HTTP/1.1 200`.

Optional desktop launcher:

- Build once: `cd ~/longwei-dev && ./scripts/build-macos-publish-app.sh`
- Then double click `~/Desktop/PublishLongweiSite.app`.

## Certificate Workflow

- Manual cert push:
  - `cd ~/longwei-dev && ./scripts/push-cert-to-cdn.sh`
- Install renew hook (one-time):
  - `cd ~/longwei-dev && ./scripts/install-acme-hook.sh`
- acme cron already exists; renew hook must keep working.

## Hard Rules

- Do not change bucket to public ACL/policy.
- Do not remove CDN `https_force` config.
- Do not remove CDN `host_redirect` rule for `/ -> /index.html`.
- Never hardcode AccessKey in repository files.
- Keep secrets only in `~/.config/longwei-site/deploy.env` (permission `600`).

## Security Notes

- If AccessKey was exposed in chat/history, rotate keys in Aliyun console.
- After rotation, update `deploy.env`.
- If CDN private OSS auth is enabled with old key, update CDN `l2_oss_key` accordingly.

## Handoff

When finishing work, report:

1. What files changed.
2. Whether deploy was run.
3. Verification result for both HTTPS domains.
4. Any pending manual action (for example AccessKey rotation).
