# =============================================================================
# GENERATE_DATA.PY - Creates Synthetic User Interaction Data
# =============================================================================
# WHAT IS THIS FILE?
# This script generates FAKE (synthetic) data for training a recommendation model.
# It creates users, courses, and simulates user behavior (who bought what).
#
# WHY DO WE NEED SYNTHETIC DATA?
# - Real user data is hard to get and may contain privacy issues
# - Synthetic data lets us control the patterns for testing
# - We can generate as much data as we need
#
# OUTPUT: data/user_interactions.json
# =============================================================================

import json
import random
import time
from datetime import datetime, timedelta

# =============================================================================
# CONFIGURATION - How much data to generate
# =============================================================================
NUM_USERS = 1000         # Number of fake users to create
NUM_COURSES = 50         # Number of fake courses to create
NUM_INTERACTIONS = 10000 # Number of user-course interactions

# =============================================================================
# COURSE CATEGORIES - Types of courses in our platform
# =============================================================================
CATEGORIES = [
    'Blockchain', 'Web Development', 'Mobile Development', 
    'Data Science', 'AI & Machine Learning', 'Cybersecurity', 
    'Design', 'Business'
]

# Skill levels for courses
LEVELS = ['Beginner', 'Intermediate', 'Advanced']


# =============================================================================
# FUNCTION 1: Generate Fake Users
# =============================================================================
# Creates users with random preferences
# 
# Example output:
# {
#   'userId': 'user_42',
#   'preferred_category': 'Web Development',  # What they like
#   'skill_level': 'Beginner'                 # Their level
# }
def generate_users(num):
    users = []
    for i in range(num):
        users.append({
            'userId': f'user_{i}',
            'preferred_category': random.choice(CATEGORIES),  # Random favorite category
            'skill_level': random.choice(LEVELS)              # Random skill level
        })
    return users


# =============================================================================
# FUNCTION 2: Generate Fake Courses
# =============================================================================
# Creates courses with random properties
#
# Example output:
# {
#   'courseId': 'course_7',
#   'title': 'Web Development Course 7',
#   'category': 'Web Development',
#   'level': 'Intermediate',
#   'price': 0.125,  # In ETH
#   'rating': 4.3
# }
def generate_courses(num):
    courses = []
    for i in range(num):
        category = random.choice(CATEGORIES)
        courses.append({
            'courseId': f'course_{i}',
            'title': f'{category} Course {i}',
            'category': category,
            'level': random.choice(LEVELS),
            'price': round(random.uniform(0.01, 0.5), 3),    # Random price 0.01-0.5 ETH
            'rating': round(random.uniform(3.5, 5.0), 1)     # Random rating 3.5-5.0
        })
    return courses


# =============================================================================
# FUNCTION 3: Generate User-Course Interactions
# =============================================================================
# Simulates which users viewed/bought which courses
# 
# KEY INSIGHT: Users are MORE likely to buy courses in their preferred category!
# This creates realistic patterns for the model to learn.
#
# purchased = 1 means user bought the course
# purchased = 0 means user viewed but didn't buy
def generate_interactions(users, courses, num):
    interactions = []
    
    for _ in range(num):
        user = random.choice(users)  # Pick a random user
        
        # REALISTIC BEHAVIOR:
        # 70% of the time, user looks at courses in their preferred category
        # 30% of the time, user explores other categories
        if random.random() < 0.7:
            # Pick from preferred category (more likely scenario)
            category_courses = [c for c in courses if c['category'] == user['preferred_category']]
            if category_courses:
                course = random.choice(category_courses)
            else:
                course = random.choice(courses)
        else:
            # Random exploration (less likely)
            course = random.choice(courses)
            
        # =================================================================
        # PURCHASE PROBABILITY CALCULATION
        # =================================================================
        # Base probability of purchase = 30%
        # +30% if category matches user's preference
        # +20% if level matches user's skill level
        # =================================================================
        purchased = 0
        prob = 0.3  # Base 30% chance
        
        if course['category'] == user['preferred_category']:
            prob += 0.3  # +30% if matching category
        if course['level'] == user['skill_level']:
            prob += 0.2  # +20% if matching level
            
        # Roll the dice - did user purchase?
        if random.random() < prob:
            purchased = 1  # Yes, bought it!
            
        # Record this interaction
        interactions.append({
            'userId': user['userId'],
            'courseId': course['courseId'],
            'purchased': purchased,  # 1 = bought, 0 = just viewed
            'timestamp': int(time.time())
        })
        
    return interactions


# =============================================================================
# MAIN FUNCTION - Run the data generation
# =============================================================================
def main():
    print("Generating synthetic data...")
    
    # Step 1: Create fake users
    users = generate_users(NUM_USERS)
    
    # Step 2: Create fake courses
    courses = generate_courses(NUM_COURSES)
    
    # Step 3: Simulate interactions
    interactions = generate_interactions(users, courses, NUM_INTERACTIONS)
    
    # Step 4: Save everything to JSON file
    data = {
        'users': users,
        'courses': courses,
        'interactions': interactions
    }
    
    with open('data/user_interactions.json', 'w') as f:
        json.dump(data, f, indent=2)
        
    print(f"Generated {len(users)} users, {len(courses)} courses, {len(interactions)} interactions.")
    print("Saved to data/user_interactions.json")


# Run the script when executed directly
if __name__ == '__main__':
    main()
