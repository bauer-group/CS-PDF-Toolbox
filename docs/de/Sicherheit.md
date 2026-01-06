# Sicherheit & Login

Dokumentation der Sicherheitsfunktionen und Authentifizierungsoptionen.

## Login aktivieren

Für Produktionsumgebungen wird dringend empfohlen, die Login-Pflicht zu aktivieren:

```bash
SECURITY_ENABLE_LOGIN=true
```

### Initiale Admin-Zugangsdaten

```bash
SECURITY_INITIAL_LOGIN_USERNAME=admin
SECURITY_INITIAL_LOGIN_PASSWORD=  # Leer lassen, von generate-secrets.sh generiert
```

Das initiale Passwort wird nur beim **ersten Start** verwendet. Danach können Sie:

1. Das Passwort im Web-Interface ändern
2. Weitere Benutzer anlegen

### Secrets generieren

```bash
# Mit Tools-Container
./tools/run.sh -s './scripts/generate-secrets.sh'

# Direkt
./scripts/generate-secrets.sh
```

Das Skript generiert:

- `SECURITY_INITIAL_LOGIN_PASSWORD`: Sicheres Admin-Passwort
- Optionaler API-Key

## Login-Methoden

```bash
# all: Username/Passwort + OAuth
# normal: Nur Username/Passwort
# oauth2: Nur OAuth (nach initialer Einrichtung)
SECURITY_LOGIN_METHOD=all
```

## Rate Limiting

Schutz vor Brute-Force-Angriffen:

```bash
# Maximale Login-Versuche (-1 = deaktiviert, fail2ban verwenden)
SECURITY_LOGIN_ATTEMPT_COUNT=5

# Sperrzeit in Minuten
SECURITY_LOGIN_RESET_TIME_MINUTES=120
```

## CSRF-Schutz

```bash
# NIEMALS in Produktion deaktivieren!
SECURITY_CSRF_DISABLED=false
```

## OAuth 2.0 / SSO

### Voraussetzungen

- `SECURITY_ENABLE_LOGIN=true` muss aktiv sein
- OAuth-Provider muss konfiguriert sein

### Allgemeine Konfiguration

```bash
SECURITY_OAUTH2_ENABLED=true
SECURITY_OAUTH2_PROVIDER=keycloak  # google, github, keycloak, authentik
```

### Keycloak / Generisches OIDC

```bash
SECURITY_OAUTH2_ISSUER=https://your-idp.com/realms/your-realm
SECURITY_OAUTH2_CLIENT_ID=stirling-pdf
SECURITY_OAUTH2_CLIENT_SECRET=your-client-secret
SECURITY_OAUTH2_SCOPES=openid, profile, email
SECURITY_OAUTH2_USE_AS_USERNAME=preferred_username
```

### Automatische Benutzer-Erstellung

```bash
# Benutzer bei erstem OAuth-Login automatisch anlegen
SECURITY_OAUTH2_AUTO_CREATE_USER=true
```

### Google OAuth

```bash
SECURITY_OAUTH2_PROVIDER=google
SECURITY_OAUTH2_CLIENT_ID=your-google-client-id
SECURITY_OAUTH2_CLIENT_SECRET=your-google-client-secret
```

### GitHub OAuth

```bash
SECURITY_OAUTH2_PROVIDER=github
SECURITY_OAUTH2_CLIENT_ID=your-github-client-id
SECURITY_OAUTH2_CLIENT_SECRET=your-github-client-secret
```

## API-Authentifizierung

### Globaler API-Key

```bash
SECURITY_CUSTOM_GLOBAL_API_KEY=your-secure-api-key
```

Verwendung:

```bash
curl -H "X-Api-Key: your-secure-api-key" \
  https://pdf.app.bauer-group.com/api/v1/info/status
```

### Benutzer-API-Keys

Jeder Benutzer kann im Web-Interface einen eigenen API-Key erstellen:

1. Login im Web-Interface
2. Kontoeinstellungen öffnen
3. API-Key generieren

## fail2ban Integration

Für zusätzlichen Schutz kann fail2ban konfiguriert werden:

### fail2ban Filter

```ini
# /etc/fail2ban/filter.d/stirling-pdf.conf
[Definition]
failregex = ^.*Invalid username or password.*client: <HOST>.*$
ignoreregex =
```

### fail2ban Jail

```ini
# /etc/fail2ban/jail.d/stirling-pdf.conf
[stirling-pdf]
enabled = true
filter = stirling-pdf
logpath = /var/log/stirling-pdf/invalid-auths.log
maxretry = 5
bantime = 3600
```

### Log-Pfad mounten

```yaml
volumes:
  - '/var/log/stirling-pdf:/logs'
```

## Sicherheits-Best-Practices

### Produktionsumgebung

1. **Login aktivieren**: `SECURITY_ENABLE_LOGIN=true`
2. **CSRF aktiviert lassen**: `SECURITY_CSRF_DISABLED=false`
3. **HTTPS verwenden**: Immer über Reverse Proxy mit TLS
4. **Starke Passwörter**: `generate-secrets.sh` verwenden
5. **Rate Limiting**: Aktivieren oder fail2ban nutzen
6. **Updates**: Regelmäßig aktualisieren

### Netzwerk

1. **Nur über Reverse Proxy**: Port 8080 nicht direkt exponieren
2. **Internal Network**: Container nur im internen Netzwerk
3. **Firewall**: Nur 80/443 öffnen

### Container

```yaml
security_opt:
  - no-new-privileges:true
read_only: true  # Wo möglich
```

## Session-Management

```bash
# Session-Timeout (z.B. 30m, 1h)
SERVER_SESSION_TIMEOUT=30m
```

## Logging für Sicherheit

```bash
# Für Security-Debugging
LOGGING_LEVEL=DEBUG

# OAuth-Probleme debuggen
LOGGING_LEVEL_ORG_SPRINGFRAMEWORK_SECURITY_OAUTH2=DEBUG
```

### Log-Dateien

| Datei | Inhalt |
|-------|--------|
| `/logs/stirling-pdf.log` | Allgemeine Logs |
| `/logs/invalid-auths.log` | Fehlgeschlagene Login-Versuche |

## Weiterführende Dokumentation

- [Installation](Installation.md)
- [Konfiguration](Konfiguration.md)
- [API-Dokumentation](API.md)
