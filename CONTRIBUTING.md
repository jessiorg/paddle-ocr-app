# Contributing to PaddleOCR Application

Thank you for considering contributing to this project! 🎉

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported
2. Create a new issue with:
   - Clear title
   - Detailed description
   - Steps to reproduce
   - Expected vs actual behavior
   - System information (OS, Docker version, etc.)
   - Logs if applicable

### Suggesting Enhancements

1. Check if the feature has been suggested
2. Create a new issue with:
   - Clear description of the feature
   - Use cases
   - Possible implementation approach
   - Any relevant examples

### Pull Requests

1. **Fork the repository**

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the existing code style
   - Add tests if applicable
   - Update documentation
   - Add comments for complex logic

4. **Test your changes**
   ```bash
   # Run tests
   pytest tests/
   
   # Test deployment
   ./scripts/deploy.sh
   
   # Test API
   ./scripts/test-api.sh
   ```

5. **Commit your changes**
   ```bash
   git commit -m "Add feature: your feature description"
   ```
   
   Commit message format:
   - `Add feature: description` - New features
   - `Fix bug: description` - Bug fixes
   - `Update docs: description` - Documentation
   - `Refactor: description` - Code refactoring
   - `Test: description` - Adding tests

6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request**
   - Clear title and description
   - Reference any related issues
   - Include screenshots for UI changes
   - List any breaking changes

## Development Setup

### Local Development

```bash
# Clone the repository
git clone https://github.com/jessiorg/paddle-ocr-app.git
cd paddle-ocr-app

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate  # Windows

# Install dependencies
pip install -r requirements.txt

# Run locally
uvicorn api.main:app --reload
```

### Code Style

**Python**:
- Follow PEP 8
- Use type hints
- Maximum line length: 100 characters
- Use meaningful variable names

**JavaScript**:
- Use ES6+ features
- Consistent indentation (2 spaces)
- Use const/let, avoid var
- Add JSDoc comments for functions

**CSS**:
- Use CSS variables
- Mobile-first approach
- Comment sections clearly

### Testing

```bash
# Run unit tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=api --cov-report=html

# Run specific test
pytest tests/test_api.py::TestHealthEndpoints::test_health_check
```

## Project Structure

```
paddle-ocr-app/
├── api/                    # Backend API code
├── frontend/               # Frontend files
├── nginx/                  # Nginx configurations
├── scripts/                # Deployment and utility scripts
├── tests/                  # Test files
├── docs/                   # Documentation
├── examples/               # Example images
├── Dockerfile              # Container definition
├── requirements.txt        # Python dependencies
└── docker-compose.service.yml  # Service definition
```

## Areas to Contribute

### Priority Areas

1. **Authentication & Authorization**
   - JWT implementation
   - API key management
   - User roles

2. **Batch Processing**
   - Multiple file upload
   - Queue system
   - Progress tracking

3. **Enhanced OCR Features**
   - Table detection
   - Form recognition
   - PDF support improvements

4. **UI/UX Improvements**
   - Accessibility features
   - Mobile optimization
   - Dark mode

5. **Testing**
   - Unit tests
   - Integration tests
   - E2E tests

6. **Documentation**
   - API examples
   - Video tutorials
   - Translation to other languages

### Good First Issues

Look for issues labeled `good first issue` - these are perfect for newcomers!

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers
- Accept constructive criticism
- Focus on what's best for the community
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Personal or political attacks
- Publishing others' private information
- Any other unprofessional conduct

## Questions?

Feel free to:
- Open an issue for questions
- Join discussions
- Ask in pull requests

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Recognition

Contributors will be:
- Added to CONTRIBUTORS.md
- Mentioned in release notes
- Credited in documentation

Thank you for contributing! 🚀
