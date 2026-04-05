// Mobile menu toggle
document.addEventListener('DOMContentLoaded', function() {
    const hamburger = document.querySelector('.hamburger');
    const navMenu = document.querySelector('.nav-menu');
    const navLinks = document.querySelectorAll('.nav-link');
    const currentPage = window.location.pathname.split('/').pop() || 'index.html';
    
    // Download Modal Elements
    const downloadBtn = document.getElementById('downloadBtn');
    const downloadModal = document.getElementById('downloadModal');
    const closeModal = document.querySelector('.close');
    

    // Download Modal Functions
    function openDownloadModal() {
        downloadModal.classList.add('show');
        document.body.style.overflow = 'hidden';
    }

    function closeDownloadModal() {
        downloadModal.classList.remove('show');
        document.body.style.overflow = 'auto';
    }

    // Download Modal Event Listeners
    if (downloadBtn && downloadModal) {
        downloadBtn.addEventListener('click', function(e) {
            e.preventDefault();
            openDownloadModal();
        });

        closeModal.addEventListener('click', closeDownloadModal);

        // Close modal when clicking outside
        downloadModal.addEventListener('click', function(e) {
            if (e.target === downloadModal) {
                closeDownloadModal();
            }
        });

        // Close modal with Escape key
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape' && downloadModal.classList.contains('show')) {
                closeDownloadModal();
            }
        });

        // Download source clicks
        const githubDownloadBtn = downloadModal.querySelector('a[href*="github.com"]');
        const fdroidDownloadBtn = downloadModal.querySelector('a[href*="f-droid.org"]');

        if (githubDownloadBtn) {
            githubDownloadBtn.addEventListener('click', function() {
                closeDownloadModal();
            });
        }

        if (fdroidDownloadBtn) {
            fdroidDownloadBtn.addEventListener('click', function() {
                closeDownloadModal();
            });
        }
    }

    // Variable to track if stats animation has been triggered
    let statsAnimationTriggered = false;

    // Fetch GitHub stats
    async function fetchGitHubStats() {
        try {
            // Fetch repository data
            const response = await fetch('https://api.github.com/repos/AnsahMohammad/shots-studio');
            const data = await response.json();
            
            // Fetch releases data for download count
            const releasesResponse = await fetch('https://api.github.com/repos/AnsahMohammad/shots-studio/releases');
            const releases = await releasesResponse.json();
            
            // Calculate total downloads
            let totalDownloads = 0;
            releases.forEach(release => {
                release.assets.forEach(asset => {
                    totalDownloads += asset.download_count;
                });
            });
            
            // Update hero stats - set data attributes first, then trigger animation
            const downloadsElement = document.getElementById('downloads-count');
            const starsElement = document.getElementById('stars-count');
            
            if (downloadsElement) {
                downloadsElement.dataset.target = totalDownloads;
                downloadsElement.textContent = '0'; // Start from 0
            }
            
            if (starsElement) {
                starsElement.dataset.target = data.stargazers_count;
                starsElement.textContent = '0★'; // Start from 0
            }
            
            // Update about section stats
            const aboutDownloadsElement = document.getElementById('about-downloads');
            const aboutStarsElement = document.getElementById('about-stars');
            
            if (aboutDownloadsElement) {
                aboutDownloadsElement.dataset.target = totalDownloads;
                aboutDownloadsElement.textContent = '0'; // Start from 0
            }
            
            if (aboutStarsElement) {
                aboutStarsElement.dataset.target = data.stargazers_count;
                aboutStarsElement.textContent = '0★'; // Start from 0
            }
            
            // Trigger counter animation if the stats section is visible
            const statsSection = document.querySelector('.hero-stats');
            if (statsSection) {
                const rect = statsSection.getBoundingClientRect();
                const isVisible = rect.top < window.innerHeight && rect.bottom > 0;
                
                if (isVisible && !statsAnimationTriggered) {
                    setTimeout(() => {
                        animateCounters();
                        statsAnimationTriggered = true;
                    }, 100);
                }
            }
            
        } catch (error) {
            console.log('Could not fetch GitHub stats:', error);
            // On error, trigger animation with fallback HTML values if section is visible
            const statsSection = document.querySelector('.hero-stats');
            if (statsSection && !statsAnimationTriggered) {
                const rect = statsSection.getBoundingClientRect();
                const isVisible = rect.top < window.innerHeight && rect.bottom > 0;
                
                if (isVisible) {
                    setTimeout(() => {
                        animateCounters();
                        statsAnimationTriggered = true;
                    }, 100);
                }
            }
        }
    }

    // Call fetchGitHubStats when page loads
    fetchGitHubStats();

    // Track navigation clicks
    navLinks.forEach(link => {
        link.addEventListener('click', function() {
            const linkText = this.textContent.trim();
            const linkHref = this.getAttribute('href');
        });
    });

    // Set active state for current page navigation
    navLinks.forEach(link => {
        const href = link.getAttribute('href');
        // Check if this link corresponds to the current page
        if ((href === currentPage) || 
            (currentPage === 'index.html' && href === '#home') ||
            (currentPage === '' && href === '#home') ||
            (href === currentPage && !link.classList.contains('cta-button'))) {
            link.classList.add('active');
        }
        
        // Special handling for the current page with a different active link
        if (currentPage === 'donation.html' && link.getAttribute('href') === 'donation.html') {
            // Remove the active class if we're on the donation page but not the CTA button
            if (!link.classList.contains('cta-button')) {
                link.classList.remove('active');
            }
        }
    });

    hamburger.addEventListener('click', function() {
        hamburger.classList.toggle('active');
        navMenu.classList.toggle('active');
    });

    // Close mobile menu when clicking on any link in nav menu
    document.querySelectorAll('.nav-menu a').forEach(link => {
        link.addEventListener('click', function() {
            hamburger.classList.remove('active');
            navMenu.classList.remove('active');
        });
    });

    // Smooth scrolling for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            // Skip external links or links with full URLs
            if (this.getAttribute('href').includes('://')) {
                return;
            }
            
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                const offsetTop = target.offsetTop - 70; // Account for fixed navbar
                window.scrollTo({
                    top: offsetTop,
                    behavior: 'smooth'
                });
            }
        });
    });

    // Navbar background on scroll
    window.addEventListener('scroll', function() {
        const navbar = document.querySelector('.navbar');
        if (window.scrollY > 50) {
            navbar.style.background = 'rgba(255, 255, 255, 0.98)';
        } else {
            navbar.style.background = 'rgba(255, 255, 255, 0.95)';
        }
    });

    // Intersection Observer for animations
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);

    // Observe elements for animation
    const animateElements = document.querySelectorAll('.feature-card, .step, .about-stat');
    animateElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(30px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });

    // Contact Form Handler
    const contactForm = document.getElementById('contactForm');
    if (contactForm) {
        contactForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            const name = document.getElementById('name').value;
            const subject = document.getElementById('subject').value;
            const message = document.getElementById('message').value;
            
            // Create mailto link with form data
            const mailtoLink = `mailto:mohdansah10@gmail.com?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(
                `Hi there,\n\nName: ${name}\n\nMessage:\n${message}\n\nBest regards,\n${name}`
            )}`;
            
            // Open email client
            window.location.href = mailtoLink;
            
            // Reset form
            contactForm.reset();
            
            // Show success message
            const submitBtn = contactForm.querySelector('button[type="submit"]');
            const originalText = submitBtn.innerHTML;
            submitBtn.innerHTML = '<i class="fas fa-check"></i> Email Client Opened!';
            submitBtn.style.background = 'var(--accent-color)';
            
            setTimeout(() => {
                submitBtn.innerHTML = originalText;
                submitBtn.style.background = '';
            }, 3000);
        });
    }

    // Notification system
    function showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.innerHTML = `
            <div class="notification-content">
                <span>${message}</span>
                <button class="notification-close">&times;</button>
            </div>
        `;

        // Add styles
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: ${type === 'success' ? '#10b981' : '#6366f1'};
            color: white;
            padding: 16px 20px;
            border-radius: 8px;
            box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
            z-index: 1001;
            transform: translateX(100%);
            transition: transform 0.3s ease;
            max-width: 400px;
        `;

        document.body.appendChild(notification);

        // Show notification
        setTimeout(() => {
            notification.style.transform = 'translateX(0)';
        }, 100);

        // Close functionality
        const closeBtn = notification.querySelector('.notification-close');
        closeBtn.addEventListener('click', () => {
            notification.style.transform = 'translateX(100%)';
            setTimeout(() => {
                document.body.removeChild(notification);
            }, 300);
        });

        // Auto remove after 5 seconds
        setTimeout(() => {
            if (document.body.contains(notification)) {
                notification.style.transform = 'translateX(100%)';
                setTimeout(() => {
                    document.body.removeChild(notification);
                }, 300);
            }
        }, 5000);
    }

    // Animate counters
    function animateCounters() {
        const counters = document.querySelectorAll('.stat-number, .about-stat h3');
        
        counters.forEach(counter => {
            const originalText = counter.textContent;
            const hasStars = originalText.includes('★');
            
            // Prioritize dataset.target, fallback to text content
            let target = parseInt(counter.dataset.target);
            if (!target || isNaN(target)) {
                target = parseInt(originalText.replace(/[^\d]/g, ''));
            }
            
            if (target > 0) {
                const increment = target / 200;
                let current = 0;
                
                const updateCounter = () => {
                    if (current < target) {
                        current += increment;
                        let displayValue = Math.ceil(current);
                        
                        // Format the number
                        let formattedValue;
                        if (target >= 1000000) {
                            formattedValue = (displayValue / 1000000).toFixed(1) + 'M';
                        } else if (target >= 1000) {
                            formattedValue = (displayValue / 1000).toFixed(1) + 'K';
                        } else {
                            formattedValue = displayValue.toString();
                        }
                        
                        // Add special formatting for stars
                        if (hasStars) {
                            formattedValue = Math.ceil(current) + '★';
                        }
                        
                        counter.textContent = formattedValue;
                        requestAnimationFrame(updateCounter);
                    } else {
                        // Set final value
                        let finalValue;
                        if (target >= 1000000) {
                            finalValue = (target / 1000000).toFixed(1) + 'M';
                        } else if (target >= 1000) {
                            finalValue = (target / 1000).toFixed(1) + 'K';
                        } else {
                            finalValue = target.toString();
                        }
                        
                        if (hasStars) {
                            finalValue = target + '★';
                        }
                        
                        counter.textContent = finalValue;
                    }
                };
                
                updateCounter();
            }
        });
    }

    // Trigger counter animation when stats section is visible
    const statsSection = document.querySelector('.hero-stats');
    
    if (statsSection) {
        const statsObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting && !statsAnimationTriggered) {
                    // Small delay to ensure GitHub stats have loaded
                    setTimeout(() => {
                        if (!statsAnimationTriggered) {
                            animateCounters();
                            statsAnimationTriggered = true;
                        }
                    }, 500);
                    
                    statsObserver.unobserve(entry.target);
                }
            });
        }, { threshold: 0.5 });
        
        statsObserver.observe(statsSection);
    }

    // Parallax effect for hero section
    window.addEventListener('scroll', () => {
        const scrolled = window.pageYOffset;
        const parallaxElements = document.querySelectorAll('.phone-mockup');
        
        parallaxElements.forEach(element => {
            const speed = 0.5;
            element.style.transform = `translateY(${scrolled * speed}px)`;
        });
    });

    // Add loading animation
    window.addEventListener('load', () => {
        document.body.classList.add('loaded');
        
        // Add CSS for loading animation
        const style = document.createElement('style');
        style.textContent = `
            body:not(.loaded) {
                overflow: hidden;
            }
            
            body:not(.loaded)::before {
                content: '';
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: white;
                z-index: 9999;
                display: flex;
                align-items: center;
                justify-content: center;
            }
            
            body:not(.loaded)::after {
                content: '';
                width: 50px;
                height: 50px;
                border: 3px solid #f3f3f3;
                border-top: 3px solid #6366f1;
                border-radius: 50%;
                animation: spin 1s linear infinite;
                position: fixed;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
                z-index: 10000;
            }
            
            @keyframes spin {
                0% { transform: translate(-50%, -50%) rotate(0deg); }
                100% { transform: translate(-50%, -50%) rotate(360deg); }
            }
        `;
        document.head.appendChild(style);
    });

    // Multi-Carousel functionality
    const multiCarouselSetup = () => {
        const track = document.querySelector('.multi-carousel-track');
        const slides = Array.from(document.querySelectorAll('.multi-carousel-slide'));
        const indicators = document.querySelectorAll('.multi-indicator');
        
        if (!track || slides.length === 0) return; // Exit if carousel doesn't exist
        
        let currentIndex = 0;
        let autoplayInterval;
        
        // Position slides based on current index
        const updateSlidePositions = () => {
            slides.forEach((slide, index) => {
                // Remove all position classes
                slide.classList.remove('center', 'left', 'right', 'hidden');
                
                if (index === currentIndex) {
                    slide.classList.add('center');
                } else if (index === (currentIndex - 1 + slides.length) % slides.length) {
                    slide.classList.add('left');
                } else if (index === (currentIndex + 1) % slides.length) {
                    slide.classList.add('right');
                } else {
                    slide.classList.add('hidden');
                }
            });
            
            // Update active indicator
            indicators.forEach((indicator, index) => {
                indicator.classList.toggle('active', index === currentIndex);
            });
        };
        
        const moveToSlide = (index) => {
            if (index < 0) index = slides.length - 1;
            if (index >= slides.length) index = 0;
            
            currentIndex = index;
            updateSlidePositions();
        };
        
        // Indicator clicks
        indicators.forEach((indicator, index) => {
            indicator.addEventListener('click', () => {
                moveToSlide(index);
                resetAutoplay();
            });
        });
        
        // Click on slides to navigate
        slides.forEach((slide, index) => {
            slide.addEventListener('click', () => {
                if (slide.classList.contains('left')) {
                    moveToSlide(currentIndex - 1);
                } else if (slide.classList.contains('right')) {
                    moveToSlide(currentIndex + 1);
                }
                resetAutoplay();
            });
        });
        
        // Touch swipe functionality for mobile
        let touchStartX = 0;
        let touchEndX = 0;
        
        track.addEventListener('touchstart', e => {
            touchStartX = e.changedTouches[0].screenX;
        });
        
        track.addEventListener('touchend', e => {
            touchEndX = e.changedTouches[0].screenX;
            handleSwipe();
        });
        
        const handleSwipe = () => {
            const swipeThreshold = 50;
            
            if (touchStartX - touchEndX > swipeThreshold) {
                // Swipe left, go to next slide
                moveToSlide(currentIndex + 1);
            } else if (touchEndX - touchStartX > swipeThreshold) {
                // Swipe right, go to previous slide
                moveToSlide(currentIndex - 1);
            }
            resetAutoplay();
        };
        
        // Autoplay functionality
        const startAutoplay = () => {
            autoplayInterval = setInterval(() => {
                moveToSlide(currentIndex + 1);
            }, 4000); // Change slide every 4 seconds
        };
        
        const resetAutoplay = () => {
            clearInterval(autoplayInterval);
            startAutoplay();
        };
        
        // Initialize carousel
        updateSlidePositions();
        startAutoplay();
    };
    
    // Initialize multi-carousel
    multiCarouselSetup();

});
