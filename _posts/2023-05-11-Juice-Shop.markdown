---
layout: post
title:  "OWASP Top 10 in Juice Shop"
date:   2023-05-11 22:22:22 -0400
featured_img: "/assets/juice-shop/juice-shop.png"
categories: Web Security OWASP
---

# OWASP Juice Shop Vulnerability Assessment

## Overview of OWASP Top Ten vulnerabilities:

## 1. Cross-Site Scripting (XSS)

Definition: XSS allows attackers to inject malicious scripts into web pages viewed by other users.
Juice Shop Example 1: Search field - Input `<img src=x onerror="alert('XSS')">` and an alert saying "XSS" pops up.
Juice Shop Example 2: Feedback form - An unsanitized comment box can execute injected scripts when the feedback is viewed.


## 2. Insecure Direct Object References (IDOR)

Definition: IDOR occurs when an application exposes a reference to an internal implementation object.
Juice Shop Example 1: Basket manipulation - Changing the URL from `#/basket/1` to `#/basket/2` allows you to view another user's basket.
Juice Shop Example 2: User profile access - Manipulating the user ID parameter in the API endpoint can expose other users' data.

## 3. SQL Injection (SQLi)

Definition: SQLi allows attackers to interfere with queries an application makes to its database.
Juice Shop Example 1: Login form - Entering `' OR 1=1 --` in the email field and any password logs you in as the first user in the database.
Juice Shop Example 2: User search - Manipulating the search function with SQL commands can reveal unintended data.

## 4. Sensitive Data Exposure

Definition: This happens when an application does not adequately protect sensitive information.
Juice Shop Example 1: `/ftp` directory - Looking through this directory can reveal confidential documents.
Juice Shop Example 2: Password storage - The application stores passwords in plaintext, exposing them to anyone with access to the database.

## 5. Broken Access Control

Definition: This occurs when users can perform actions outside of their privileges.
Juice Shop Example 1: Adding non-sale items - A POST request to `api/BasketItems/` with an unavailable item ID still adds the item to your basket.
Juice Shop Example 2: Administration access - Directly entering the URL `/#/administration` allows access without proper authorization.

## 6. Security Misconfiguration

Definition: This can occur when security settings are defined, implemented, and maintained as defaults.
Juice Shop Example: Administration section - Directly accessing `/#/administration` reveals poor security configuration.

## 7. Cross-Site Request Forgery (CSRF)

Definition: CSRF forces an end user to execute unwanted actions on a web application in which they're authenticated.
Juice Shop Example: Review manipulation - Creating a malicious link that changes a review, and tricking a user into clicking it, can change their review.

## 8. Insecure Deserialization

Definition: This vulnerability allows attackers to transfer a payload using serialized objects.
Juice Shop Example: Riddle cookie - Altering the serialized object in the riddle cookie can solve the riddle.

## 9. Using Components with Known Vulnerabilities

Definition: Components, such as libraries, frameworks, and other software modules, run with the same privileges as the application.
Juice Shop Example: YouTube API - An outdated YouTube API version used by the application can be exploited to reveal an Easter egg.

## 10. Insufficient Logging & Monitoring

Definition: Insufficient logging and monitoring can lead to delayed or missed responses to attacks.
