# YouTube Downloader API Pro - Варианты дистрибуции

## Цель документа

Проанализировать возможные модели дистрибуции Pro версии YouTube Downloader API и выбрать оптимальную стратегию.

---

## Сравнение вариантов

### Вариант 1: GitHub Private Repository (Подписка через Sponsors/Teams)

#### Как работает
1. Создаётся приватный репозиторий `alexbic/youtube-downloader-api-pro`
2. Клиенты получают доступ через:
   - **GitHub Sponsors** (рекомендуется) - подписка $X/месяц
   - **GitHub Team Membership** - добавление в organization team
3. Клонирование: `git clone https://github.com/alexbic/youtube-downloader-api-pro.git`
4. Обновления: `git pull`

#### Технические детали
```bash
# Пользователь подписывается через GitHub Sponsors
# После подтверждения оплаты - автоматически добавляется в team

# Доступ к репозиторию
git clone git@github.com:alexbic/youtube-downloader-api-pro.git
cd youtube-downloader-api-pro

# Обновление
git pull origin main

# Сборка
docker build -t ytdl-pro .
docker-compose up -d
```

#### Плюсы ✅
- **Просто для разработчиков** - знакомый Git workflow
- **Автоматические обновления** - просто git pull
- **GitHub Sponsors** - встроенная система оплаты (без комиссии для open-source проектов)
- **Прозрачность** - клиенты видят весь исходный код
- **Нет дополнительной инфраструктуры** - всё на GitHub
- **Version control** - клиенты могут откатываться на старые версии
- **Issues/Support** - встроенная система тикетов

#### Минусы ❌
- **Требуется GitHub аккаунт** - барьер входа для некоторых клиентов
- **Исходный код доступен** - клиенты могут форкнуть и распространять
- **Сложно отозвать доступ** - если клиент сделал fork
- **GitHub Sponsors доступен не во всех странах**

#### Стоимость внедрения
- $0 - используется существующая инфраструктура GitHub
- Нужно только настроить GitHub Sponsors или создать organization

---

### Вариант 2: Private Docker Registry (Лицензионный ключ)

#### Как работает
1. Pro образы публикуются в приватный Docker registry
2. При покупке клиент получает лицензионный ключ
3. Лицензия проверяется при запуске контейнера
4. Доступ к registry через login с лицензионным ключом

#### Технические детали
```bash
# Клиент получает лицензионный ключ после покупки
export LICENSE_KEY="abc123-def456-ghi789"

# Login в приватный registry (опционально)
docker login registry.ytdl-pro.com -u customer -p $LICENSE_KEY

# Pull образа
docker pull registry.ytdl-pro.com/youtube-downloader-api-pro:latest

# Запуск с валидацией лицензии
docker run -d \
  -e LICENSE_KEY=$LICENSE_KEY \
  -p 5000:5000 \
  registry.ytdl-pro.com/youtube-downloader-api-pro:latest
```

#### Архитектура валидации лицензии

**Вариант A: Online валидация**
```python
# При старте контейнера
import requests

def validate_license(key):
    response = requests.post(
        'https://license.ytdl-pro.com/validate',
        json={'license_key': key, 'deployment_id': get_machine_id()}
    )
    return response.json()['valid']

# Проверка каждые 24 часа
```

**Вариант B: Offline валидация (JWT)**
```python
# Лицензионный ключ = подписанный JWT токен
import jwt

def validate_license(key):
    try:
        payload = jwt.decode(key, PUBLIC_KEY, algorithms=['RS256'])
        if payload['exp'] > time.time():
            return True
    except:
        return False
```

#### Плюсы ✅
- **Защита исходного кода** - клиенты получают только Docker образ
- **Контроль доступа** - можно отключить лицензию удалённо (online валидация)
- **Простой деплой** - просто docker pull + docker run
- **Гибкая валидация** - можно ограничить по времени, количеству установок
- **Привычный workflow** - docker pull как для public версии

#### Минусы ❌
- **Требуется инфраструктура** - приватный registry (Docker Hub Pro ~$7/месяц или свой)
- **Лицензионный сервер** - нужен для online валидации (можно обойтись JWT)
- **Сложность внедрения** - нужно реализовать валидацию
- **Нет исходного кода** - клиенты не видят код (может быть проблемой для enterprise)

#### Стоимость внедрения
- **Docker Hub Private Repo**: $7/месяц
- **Harbor (self-hosted)**: $0 но нужен сервер (~$10-20/месяц)
- **AWS ECR**: ~$0.10/GB/месяц
- **Лицензионный сервер**: $5-10/месяц (simple Flask app)

**Рекомендация**: Docker Hub Private Repo + JWT валидация (без отдельного сервера)

---

### Вариант 3: Hybrid (Лучшее из двух миров)

#### Как работает
1. **Individual/Team** - GitHub Private Repo через GitHub Sponsors
2. **Enterprise** - Private Docker Registry с лицензионными ключами
3. **Landing page** - для маркетинга и генерации ключей

#### Архитектура
```
Landing Page (ytdl-pro.com)
    ├── Individual Plan ($29/mo) → GitHub Sponsors → Private Repo Access
    ├── Team Plan ($99/mo) → GitHub Sponsors → Private Repo Access (5 users)
    └── Enterprise Plan (Custom) → License Key → Private Docker Registry
```

#### Технические детали

**Для Individual/Team:**
```bash
# После подписки через GitHub Sponsors
git clone git@github.com:alexbic/youtube-downloader-api-pro.git
cd youtube-downloader-api-pro
docker-compose up -d
```

**Для Enterprise:**
```bash
# После покупки получают license key
docker pull registry.ytdl-pro.com/youtube-downloader-api-pro:latest
docker run -e LICENSE_KEY=xxx -p 5000:5000 ...
```

#### Плюсы ✅
- **Гибкость** - разные модели для разных клиентов
- **Максимизация аудитории** - разработчики на GitHub, enterprise через Docker
- **Защита и прозрачность** - GitHub для open-source комьюнити, Docker для корпораций

#### Минусы ❌
- **Сложность поддержки** - нужно поддерживать два канала дистрибуции
- **Стоимость** - нужно всё: landing page + GitHub + Docker registry

#### Стоимость внедрения
- Landing page: $10-20/месяц (Vercel/Netlify)
- Docker Hub: $7/месяц
- Домен: $12/год
- **Итого**: ~$30/месяц

---

### Вариант 4: GitHub Releases (Приватный репозиторий + Downloads)

#### Как работает
1. Private репозиторий `youtube-downloader-api-pro`
2. При покупке клиент получает Personal Access Token
3. Скачивание через GitHub Releases API
4. Docker образы прикреплены к релизам

#### Технические детали
```bash
# Клиент получает Personal Access Token после оплаты
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"

# Скачивание latest release
curl -H "Authorization: token $GITHUB_TOKEN" \
  -L https://api.github.com/repos/alexbic/youtube-downloader-api-pro/releases/latest \
  -o release.json

# Извлечение Docker образа из assets
docker load < youtube-downloader-api-pro-v1.0.0.tar.gz
```

#### Плюсы ✅
- **Простая реализация** - используется только GitHub
- **Контроль версий** - клиенты могут выбрать версию
- **Оффлайн** - после скачивания не нужен интернет

#### Минусы ❌
- **Ручные обновления** - клиенты должны повторно скачивать
- **Большие файлы** - Docker образы могут быть 1GB+
- **Неудобно** - сложнее чем docker pull

---

## Анализ платёжных систем

### GitHub Sponsors (Рекомендуется для Individual/Team)

**Плюсы:**
- ✅ Интеграция с GitHub - автоматическое управление доступом
- ✅ Без комиссии для open-source maintainers (0%)
- ✅ Recurring payments встроены
- ✅ Простая настройка ($29/mo, $99/mo, $299/mo tiers)

**Минусы:**
- ❌ Доступно не во всех странах
- ❌ Требуется публичный GitHub profile

**Настройка:**
```yaml
# .github/FUNDING.yml
github: alexbic

# Tiers в GitHub Sponsors:
# - Individual: $29/month → read access to private repo
# - Team: $99/month → read access for 5 users
# - Enterprise: $299/month → read access + priority support
```

### Stripe/Paddle (Для Docker Registry модели)

**Плюсы:**
- ✅ Работает во всех странах
- ✅ Гибкие subscription модели
- ✅ Webhooks для автоматизации
- ✅ Поддержка invoicing для компаний

**Минусы:**
- ❌ Комиссия 2.9% + $0.30 (Stripe) или 5% + $0.50 (Paddle)
- ❌ Нужна интеграция с landing page

---

## Рекомендация: Hybrid подход с фокусом на GitHub

### Стартовая конфигурация (MVP)

**Phase 1: GitHub Sponsors Only**
1. Создать `alexbic/youtube-downloader-api-pro` private repo
2. Настроить GitHub Sponsors с тремя тирами:
   - **Individual**: $29/month - 1 deployment, source code access
   - **Team**: $99/month - 5 deployments, source code access
   - **Enterprise**: Contact us - unlimited deployments + SLA
3. Автоматизация: GitHub Actions добавляет sponsors в team с read access
4. Простой landing на GitHub Pages: https://alexbic.github.io/youtube-downloader-api-pro

**Технический стек:**
- GitHub Private Repo (бесплатно)
- GitHub Sponsors (0% комиссия)
- GitHub Pages для landing (бесплатно)
- **Общая стоимость: $0/месяц**

**Автоматизация доступа:**
```yaml
# .github/workflows/manage-sponsors.yml
name: Manage Sponsor Access
on:
  sponsorship:
    types: [created, cancelled]

jobs:
  manage-access:
    runs-on: ubuntu-latest
    steps:
      - name: Add sponsor to team
        if: github.event.action == 'created'
        run: |
          gh api /orgs/your-org/teams/pro-users/memberships/${{ github.event.sponsorship.sponsor.login }} \
            -X PUT

      - name: Remove sponsor from team
        if: github.event.action == 'cancelled'
        run: |
          gh api /orgs/your-org/teams/pro-users/memberships/${{ github.event.sponsorship.sponsor.login }} \
            -X DELETE
```

---

### Phase 2: Добавление Docker Registry (После 50+ клиентов)

Когда есть стабильная клиентская база:

1. Настроить Docker Hub Private Repo ($7/месяц)
2. Добавить tier "Enterprise Docker" ($199/month)
3. Реализовать JWT валидацию лицензий (без отдельного сервера)
4. Полноценный landing на Vercel/Netlify

**Общая стоимость: ~$30/месяц**

---

## Детальный план внедрения Phase 1

### Шаг 1: Создание приватного репозитория
```bash
# Создать приватный репозиторий (через GitHub UI или gh CLI)
gh repo create alexbic/youtube-downloader-api-pro \
  --private \
  --description "YouTube Downloader API Pro - PostgreSQL, configurable limits, advanced features"
```

### Шаг 2: Настройка GitHub Sponsors

1. Включить GitHub Sponsors на своём профиле: https://github.com/sponsors
2. Настроить банковский счёт или Stripe Connect
3. Создать тиры:

**Individual Tier ($29/month)**
```
Title: Individual License
Description: Perfect for solo developers and small projects

Includes:
- ✅ Full source code access
- ✅ 1 production deployment
- ✅ GitHub Issues support
- ✅ All Pro features (PostgreSQL, configurable TTL, etc.)
- ✅ Updates via git pull
```

**Team Tier ($99/month)**
```
Title: Team License
Description: For small teams and growing businesses

Includes:
- ✅ Everything in Individual
- ✅ Up to 5 production deployments
- ✅ Up to 5 team members
- ✅ Priority GitHub Issues support
- ✅ Email support
```

**Enterprise Tier (One-time $299 or Custom)**
```
Title: Enterprise License
Description: Custom solution for large organizations

Includes:
- ✅ Everything in Team
- ✅ Unlimited deployments
- ✅ Unlimited team members
- ✅ SLA support (24h response time)
- ✅ Custom features development
- ✅ Installation assistance

Contact: support@alexbic.net for quote
```

### Шаг 3: Автоматизация доступа

**Вариант A: Ручной (MVP)**
- Sponsors пишут в Issues или email
- Вы вручную добавляете их в private repo collaborators

**Вариант B: Полуавтоматический (Рекомендуется)**
```yaml
# .github/workflows/notify-sponsor.yml
name: Notify New Sponsor
on:
  sponsorship:
    types: [created]

jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - name: Create issue with instructions
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.create({
              owner: context.repo.owner,
              repo: 'youtube-downloader-api-pro',
              title: `Welcome @${{ github.event.sponsorship.sponsor.login }}!`,
              body: `
                Thank you for sponsoring! 🎉

                You now have access to this repository.

                Get started:
                \`\`\`bash
                git clone git@github.com:alexbic/youtube-downloader-api-pro.git
                cd youtube-downloader-api-pro
                cp .env.example .env
                # Configure your environment
                docker-compose up -d
                \`\`\`

                Documentation: [docs/README.md](docs/README.md)
                Support: [Issues](https://github.com/alexbic/youtube-downloader-api-pro/issues)
              `,
              assignees: ['alexbic']
            })
```

### Шаг 4: Landing Page (GitHub Pages)

Создать простую страницу `docs/index.html`:
```html
<!DOCTYPE html>
<html>
<head>
    <title>YouTube Downloader API Pro</title>
    <meta name="description" content="Professional YouTube video downloader with PostgreSQL, configurable limits">
</head>
<body>
    <h1>YouTube Downloader API Pro</h1>

    <h2>Features</h2>
    <ul>
        <li>PostgreSQL storage</li>
        <li>Configurable workers (1-10+)</li>
        <li>Configurable TTL (hours to months)</li>
        <li>Advanced search & filtering</li>
        <li>Priority support</li>
    </ul>

    <h2>Pricing</h2>
    <div class="pricing">
        <div class="tier">
            <h3>Individual - $29/month</h3>
            <ul>
                <li>1 deployment</li>
                <li>Source code access</li>
                <li>GitHub Issues support</li>
            </ul>
            <a href="https://github.com/sponsors/alexbic?tier_id=XXX">Subscribe</a>
        </div>

        <div class="tier">
            <h3>Team - $99/month</h3>
            <ul>
                <li>5 deployments</li>
                <li>5 team members</li>
                <li>Priority support</li>
            </ul>
            <a href="https://github.com/sponsors/alexbic?tier_id=YYY">Subscribe</a>
        </div>

        <div class="tier">
            <h3>Enterprise - Contact Us</h3>
            <ul>
                <li>Unlimited deployments</li>
                <li>SLA support</li>
                <li>Custom features</li>
            </ul>
            <a href="mailto:support@alexbic.net">Contact</a>
        </div>
    </div>

    <h2>Comparison: Public vs Pro</h2>
    <table>
        <tr>
            <th>Feature</th>
            <th>Public (Free)</th>
            <th>Pro</th>
        </tr>
        <tr>
            <td>Workers</td>
            <td>2 (fixed)</td>
            <td>1-10+ (configurable)</td>
        </tr>
        <tr>
            <td>TTL</td>
            <td>24h (fixed)</td>
            <td>Hours to months</td>
        </tr>
        <tr>
            <td>Storage</td>
            <td>Redis (256MB)</td>
            <td>PostgreSQL</td>
        </tr>
        <tr>
            <td>Search</td>
            <td>By task_id only</td>
            <td>Advanced filtering</td>
        </tr>
        <tr>
            <td>Support</td>
            <td>GitHub Issues</td>
            <td>Priority + Email</td>
        </tr>
    </table>
</body>
</html>
```

Включить GitHub Pages: Settings → Pages → Source: `main` branch, `/docs` folder

---

## Итоговая рекомендация

### Для старта (первые 6 месяцев):

**✅ Используйте GitHub Sponsors + Private Repository**

**Почему:**
1. **Нулевые затраты** - нет инфраструктуры, нет комиссий
2. **Быстрый запуск** - можно настроить за 1 день
3. **Прозрачность** - разработчики любят видеть код
4. **Простота** - знакомый Git workflow
5. **Встроенная платежная система** - GitHub Sponsors

**Минимальный набор:**
- Private repo на GitHub
- GitHub Sponsors с 2-3 тирами
- Простая landing page на GitHub Pages
- README с инструкциями по началу работы

**Время внедрения: 1-2 дня**
**Стоимость: $0/месяц**

---

### Для масштабирования (после 50+ клиентов):

**✅ Добавить Docker Registry + License Keys для Enterprise**

**Когда добавлять:**
- Есть 50+ активных подписчиков
- Появляются запросы от enterprise клиентов
- Есть запросы на Docker-only решение (без исходного кода)

**Дополнительные компоненты:**
- Docker Hub Private Repo ($7/месяц)
- Полноценный landing на домене (Vercel, $10-20/месяц)
- JWT валидация лицензий (код в приложении)

**Время внедрения: 1-2 недели**
**Дополнительная стоимость: ~$30/месяц**

---

## Следующие шаги

### Немедленные действия:
1. ✅ Создать private repo `youtube-downloader-api-pro`
2. ✅ Включить GitHub Sponsors
3. ✅ Настроить 2-3 тира ($29, $99, Enterprise)
4. ✅ Создать базовую landing page на GitHub Pages
5. ✅ Перенести Pro функционал из текущей ветки в новый репо
6. ✅ Написать документацию для Pro версии
7. ✅ Анонсировать в публичном репо (ссылка в README)

### Опционально:
- Настроить автоматизацию через GitHub Actions (notify sponsors)
- Зарегистрировать домен `ytdl-pro.com` для будущего landing page
- Подготовить email templates для onboarding клиентов

---

**Документ подготовлен:** 2025-11-18
**Автор:** Claude Code
**Статус:** Recommendation for implementation
