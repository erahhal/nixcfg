# ProtonMail Bridge + Thunderbird Setup

Thunderbird and protonmail-bridge are configured declaratively, but the bridge requires one-time setup for credential storage and login.

## 0. Initialize password store

ProtonMail Bridge uses `pass` (password-store) to persist credentials. It must be initialized with a GPG key before the bridge can save login state.

```bash
# List available GPG keys
gpg --list-keys

# Initialize pass with your GPG key ID
pass init <GPG_KEY_ID>
```

Without this, the bridge will lose credentials on every restart.

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
