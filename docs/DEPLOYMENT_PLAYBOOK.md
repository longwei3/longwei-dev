# Deployment Playbook

This playbook is for humans and AI agents maintaining `longwei.org.cn`.

## 1. Prerequisites

- Local project path: `~/longwei-dev`
- Aliyun CLI installed (`aliyun version`)
- Valid RAM AccessKey with OSS/CDN/DNS permissions
- Config file:
  - `~/.config/longwei-site/deploy.env`

Minimal required fields in `deploy.env`:

```bash
ALIYUN_ACCESS_KEY_ID=
ALIYUN_ACCESS_KEY_SECRET=
SOURCE_DIR=${HOME}/longwei-dev
OSS_BUCKET=longwei-org-cn-site-20260226205642
OSS_REGION=cn-hongkong
CDN_API_REGION=cn-hangzhou
CDN_DOMAINS=www.longwei.org.cn,longwei.org.cn
CERT_FULLCHAIN=${HOME}/.acme.sh/longwei.org.cn_ecc/fullchain.cer
CERT_KEY=${HOME}/.acme.sh/longwei.org.cn_ecc/longwei.org.cn.key
```

Create template:

```bash
cd ~/longwei-dev
./scripts/setup-site-env.sh
```

## 2. Normal Website Update

1. Edit site files (`index.html`, images, etc.).
2. Deploy:

```bash
cd ~/longwei-dev
./scripts/deploy-site.sh
```

What this script does:

- Builds a clean staging folder (excluding `.git`, `scripts`, `README.md`).
- Syncs staging files to OSS bucket.
- Deletes removed files from OSS.
- Refreshes CDN cache for `/` and `/index.html` on both domains.

### macOS Double-Click Publish (Optional)

Build launcher app:

```bash
cd ~/longwei-dev
./scripts/build-macos-publish-app.sh
```

Then run by double click:

- `~/Desktop/PublishLongweiSite.app`

## 3. Verify After Deploy

```bash
curl -I https://www.longwei.org.cn/
curl -I https://longwei.org.cn/
curl -I http://www.longwei.org.cn/
curl -I http://longwei.org.cn/
```

Expected:

- HTTPS: `200`
- HTTP: `301` redirect to HTTPS

## 4. Certificate Operations

Manual push current cert to CDN:

```bash
cd ~/longwei-dev
./scripts/push-cert-to-cdn.sh
```

Install auto-renew hook (one-time):

```bash
cd ~/longwei-dev
./scripts/install-acme-hook.sh
```

Daily acme cron should call renew automatically. The renew hook must trigger `push-cert-to-cdn.sh`.

## 5. CDN/OSS Critical Configs (Do Not Break)

- OSS bucket must stay **private**.
- CDN must keep private OSS auth (`l2_oss_key`).
- CDN must keep path rewrite:
  - `host_redirect`: `^/$ -> /index.html`
- CDN must keep HTTPS redirect:
  - `https_force`: `enable=on`, `https_rewrite=301`

## 6. Common Troubleshooting

`403` on homepage:

- Check `host_redirect` exists for `/ -> /index.html`.
- Check CDN private OSS auth key is valid.

`Website not updated`:

- Re-run `./scripts/deploy-site.sh`.
- Re-check CDN cache refresh output.

`HTTPS cert invalid/old`:

- Run `./scripts/push-cert-to-cdn.sh`.
- Verify cert on live domain:

```bash
echo | openssl s_client -connect www.longwei.org.cn:443 -servername www.longwei.org.cn 2>/dev/null | openssl x509 -noout -subject -issuer -dates
```

## 7. Security Maintenance

- Keep `~/.config/longwei-site/deploy.env` permission `600`.
- Never commit secrets into git.
- Rotate AccessKey if exposed.
- After key rotation:
  - update `deploy.env`
  - verify deploy still works
  - verify CDN private OSS auth uses valid key
