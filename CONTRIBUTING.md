# Contributing to Flight Price Monitor

First off, thank you for considering contributing to Flight Price Monitor! 🎉

It's people like you that make this project better for everyone who wants to save money on flights.

## 🎯 Ways to Contribute

### 🐛 Reporting Bugs

If you find a bug, please open an issue with:
- **Clear title** describing the issue
- **Steps to reproduce** the bug
- **Expected vs actual behavior**
- **Screenshots** if applicable
- **Environment** (OS, Python version, etc.)

### 💡 Suggesting Features

Have an idea? Open an issue with:
- **Clear description** of the feature
- **Use case** - why is this needed?
- **Mockups or examples** if applicable

### 📝 Improving Documentation

Documentation improvements are always welcome:
- Fix typos or unclear explanations
- Add examples
- Translate to other languages
- Add screenshots or diagrams

### 💻 Code Contributions

Want to fix a bug or add a feature? Great!

## 🔧 Development Setup

### Prerequisites

```bash
# Install dependencies
sudo apt-get install libxml2-dev libxslt-dev python3-dev build-essential

# Install Python packages
pip3 install -r requirements_raspberry.txt
```

### Fork and Clone

```bash
# 1. Fork the repository on GitHub

# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/flight-price-monitor.git
cd flight-price-monitor

# 3. Add upstream remote
git remote add upstream https://github.com/ORIGINAL_OWNER/flight-price-monitor.git
```

### Create a Branch

```bash
# Create a feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/bug-description
```

## 📋 Code Style

### Python

- Follow **PEP 8** style guide
- Use **meaningful variable names**
- Add **docstrings** to functions
- Keep functions **small and focused**
- Add **comments** for complex logic

Example:
```python
def search_flights_for_country(country, origin, destination, departure_date, return_date):
    """
    Search flights for a specific country using VPN.
    
    Args:
        country (str): Country code (e.g., 'brazil', 'portugal')
        origin (str): Origin airport code (e.g., 'GRU')
        destination (str): Destination airport code (e.g., 'LIS')
        departure_date (str): Departure date (YYYY-MM-DD)
        return_date (str): Return date (YYYY-MM-DD) or None
        
    Returns:
        list: List of flight results with prices and details
    """
    # Implementation
    pass
```

### Shell Scripts

- Use `#!/bin/bash` shebang
- Add `set -e` for error handling
- Comment complex sections
- Use meaningful variable names

### HTML/CSS/JavaScript

- Use **semantic HTML5**
- Keep CSS organized
- Use modern JavaScript (ES6+)
- Add comments for complex logic

## ✅ Testing Your Changes

### Manual Testing

```bash
# 1. Run the application
python3 app_v3_COMPLETO.py

# 2. Access in browser
# http://localhost:8776

# 3. Test your changes:
# - Make a search
# - Check logs
# - Verify results
# - Test on different screen sizes (mobile, tablet, desktop)
```

### Code Quality

```bash
# Check Python syntax
python3 -m py_compile app_v3_COMPLETO.py

# Check for common issues (if you have pylint)
pylint app_v3_COMPLETO.py
```

## 📝 Commit Guidelines

### Commit Messages

Use **conventional commits** format:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```bash
git commit -m "feat(scraper): add Momondo support"
git commit -m "fix(vpn): handle connection timeout properly"
git commit -m "docs(readme): add installation troubleshooting section"
git commit -m "style(ui): improve mobile responsive layout"
```

### Commit Often

Make **small, focused commits**:
- ✅ One logical change per commit
- ✅ Commit messages explain "why"
- ❌ Avoid huge commits with multiple changes

## 🔀 Pull Request Process

### Before Submitting

1. ✅ Test your changes thoroughly
2. ✅ Update documentation if needed
3. ✅ Update README if adding new features
4. ✅ Ensure no credentials are in the code
5. ✅ Make sure code follows style guidelines

### Submit Pull Request

```bash
# 1. Push your branch
git push origin feature/your-feature-name

# 2. Go to GitHub and click "New Pull Request"

# 3. Fill in the template (see below)

# 4. Wait for review
```

### PR Template

```markdown
## Description
Brief description of what this PR does.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement

## Testing
How did you test this?

## Screenshots (if applicable)
Add screenshots here

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No credentials in code
- [ ] Tested manually
```

### Review Process

1. **Maintainer reviews** your code
2. **Feedback** may be requested
3. **Make changes** if needed
4. Once approved, **maintainer merges**

Be patient! Reviews may take a few days.

## 🌟 Areas for Improvement

Looking for ideas? Here are areas that need work:

### High Priority
- [ ] Improve scraper success rate (anti-bot bypass)
- [ ] Add more travel sites (Expedia, Booking.com)
- [ ] Better error handling and user feedback
- [ ] Add unit tests
- [ ] Improve mobile interface

### Medium Priority
- [ ] Email notifications when prices drop
- [ ] Price history tracking and graphs
- [ ] More countries (target: 30+)
- [ ] Support for hotels and car rentals
- [ ] Dark mode

### Low Priority
- [ ] Telegram bot integration
- [ ] Mobile app (React Native)
- [ ] ML price prediction
- [ ] API for third-party integration
- [ ] Multi-language support

## 📚 Resources

### Documentation
- [Flask Documentation](https://flask.palletsprojects.com/)
- [BeautifulSoup Documentation](https://www.crummy.com/software/BeautifulSoup/bs4/doc/)
- [Playwright Documentation](https://playwright.dev/python/)

### Learning
- [Real Python](https://realpython.com/)
- [Python PEP 8](https://pep8.org/)
- [Git Best Practices](https://git-scm.com/book/en/v2)

## 💬 Communication

### Questions?

- 💬 Open a [Discussion](../../discussions)
- 🐛 Open an [Issue](../../issues)
- 📧 Email: your-email@example.com

### Code of Conduct

Be respectful, constructive, and professional:
- ✅ Be welcoming to newcomers
- ✅ Give constructive feedback
- ✅ Focus on the issue, not the person
- ❌ No harassment or offensive language
- ❌ No spam or trolling

## 🎓 First Time Contributing?

Don't worry! Everyone was new once. Here's a beginner-friendly workflow:

```bash
# 1. Fork the project on GitHub (click "Fork" button)

# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/flight-price-monitor.git

# 3. Create a branch for your fix
git checkout -b fix/my-first-fix

# 4. Make your changes (start small!)
# Example: fix a typo in README

# 5. Commit
git add README.md
git commit -m "docs: fix typo in installation section"

# 6. Push
git push origin fix/my-first-fix

# 7. Open Pull Request on GitHub
# Go to your fork and click "New Pull Request"

# 8. Wait for review and respond to feedback
```

**Tips for first-time contributors:**
- Start with **documentation fixes** or **small bugs**
- Ask questions if you're stuck
- Don't be afraid to make mistakes
- Learn from feedback

## 🏆 Recognition

Contributors are awesome! We recognize contributions in:
- README contributors section
- Release notes
- GitHub Insights

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

## 🙏 Thank You!

Your contributions make Flight Price Monitor better for everyone!

Happy coding! 🚀✈️💰

---

**Questions?** Open an issue or discussion - we're here to help!
