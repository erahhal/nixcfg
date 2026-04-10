# ProtonMail Bridge + Thunderbird Setup

Thunderbird and protonmail-bridge are configured declaratively, but the bridge requires a one-time interactive login.

## 1. Log in to ProtonMail Bridge

```bash
systemctl --user stop protonmail-bridge
protonmail-bridge --cli
```

In the CLI:

```
login
```

Follow the prompts to authenticate with your ProtonMail credentials (and 2FA if enabled).

## 2. Get the bridge password

Still in the CLI:

```
info
```

This shows the IMAP/SMTP credentials. Copy the **bridge-generated password** (not your ProtonMail login password).

```
exit
```

## 3. Restart the bridge

```bash
systemctl --user start protonmail-bridge
```

## 4. Enter the password in Thunderbird

Launch Thunderbird. The ProtonMail account is pre-configured. When prompted for a password, enter the bridge-generated password from step 2.
