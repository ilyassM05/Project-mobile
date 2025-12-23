# =============================================================================
# TRAIN_COURSE_SIMILARITY.PY - Course-to-Course Similarity MLP
# =============================================================================
# WHAT IS THIS FILE?
# This script trains an MLP model to learn course embeddings that capture
# content similarity. The model can then be used to recommend related courses
# (e.g., JavaScript → React, Python → Django).
#
# HOW IT'S DIFFERENT FROM train_model.py:
# - train_model.py: User → Course recommendations (personalized)
# - THIS FILE: Course → Course recommendations (content-based)
#
# This is an Embedding-Based MLP for course-to-course recommendations.
#
# OUTPUT:
# - assets/model/course_similarity_model.tflite
# - assets/model/course_similarity_encoders.json
# =============================================================================

import tensorflow as tf
import numpy as np
import json
import os

# =============================================================================
# COURSE DATA & KNOWLEDGE GRAPH
# =============================================================================
# This is our "knowledge graph" - we define:
# 1. What courses exist
# 2. Their categories and tags
# 3. Which courses are related to each other
#
# The model will learn from these relationships!
# =============================================================================

COURSES = [
    # =========================================================================
    # WEB DEVELOPMENT COURSES
    # =========================================================================
    {
        'id': 'javascript_fundamentals',
        'title': 'JavaScript Fundamentals',
        'category': 'Web Development',
        'tags': ['JavaScript', 'Frontend', 'ES6', 'Programming'],
        'related': ['react_complete', 'vue_masterclass', 'nodejs_backend', 'typescript_deep_dive']
    },
    {
        'id': 'react_complete',
        'title': 'Complete React Developer Course',
        'category': 'Web Development',
        'tags': ['React', 'JavaScript', 'Frontend', 'Hooks', 'Redux'],
        'related': ['javascript_fundamentals', 'nextjs_fullstack', 'typescript_deep_dive', 'vue_masterclass']
    },
    {
        'id': 'vue_masterclass',
        'title': 'Vue.js Masterclass',
        'category': 'Web Development',
        'tags': ['Vue', 'JavaScript', 'Frontend', 'Vuex'],
        'related': ['javascript_fundamentals', 'react_complete', 'nodejs_backend']
    },
    {
        'id': 'nodejs_backend',
        'title': 'Node.js Backend Development',
        'category': 'Web Development',
        'tags': ['Node.js', 'JavaScript', 'Backend', 'Express', 'API'],
        'related': ['javascript_fundamentals', 'mongodb_database', 'typescript_deep_dive', 'react_complete']
    },
    {
        'id': 'typescript_deep_dive',
        'title': 'TypeScript Deep Dive',
        'category': 'Web Development',
        'tags': ['TypeScript', 'JavaScript', 'Types', 'Frontend', 'Backend'],
        'related': ['javascript_fundamentals', 'react_complete', 'nodejs_backend', 'angular_complete']
    },
    {
        'id': 'nextjs_fullstack',
        'title': 'Next.js Full Stack Development',
        'category': 'Web Development',
        'tags': ['Next.js', 'React', 'Fullstack', 'SSR', 'JavaScript'],
        'related': ['react_complete', 'nodejs_backend', 'typescript_deep_dive']
    },
    {
        'id': 'angular_complete',
        'title': 'Angular Complete Guide',
        'category': 'Web Development',
        'tags': ['Angular', 'TypeScript', 'Frontend', 'RxJS'],
        'related': ['typescript_deep_dive', 'react_complete', 'javascript_fundamentals']
    },
    {
        'id': 'html_css_modern',
        'title': 'Modern HTML & CSS',
        'category': 'Web Development',
        'tags': ['HTML', 'CSS', 'Frontend', 'Responsive', 'Flexbox'],
        'related': ['javascript_fundamentals', 'react_complete', 'ui_ux_design']
    },

    # =========================================================================
    # MOBILE DEVELOPMENT COURSES
    # =========================================================================
    {
        'id': 'flutter_complete',
        'title': 'Complete Flutter Development Bootcamp',
        'category': 'Mobile Development',
        'tags': ['Flutter', 'Dart', 'Mobile', 'Cross-Platform', 'iOS', 'Android'],
        'related': ['dart_fundamentals', 'react_native_complete', 'firebase_flutter', 'ui_ux_design']
    },
    {
        'id': 'dart_fundamentals',
        'title': 'Dart Programming Fundamentals',
        'category': 'Mobile Development',
        'tags': ['Dart', 'Programming', 'OOP', 'Flutter'],
        'related': ['flutter_complete', 'python_fundamentals', 'javascript_fundamentals']
    },
    {
        'id': 'react_native_complete',
        'title': 'React Native - Build Mobile Apps',
        'category': 'Mobile Development',
        'tags': ['React Native', 'JavaScript', 'Mobile', 'iOS', 'Android'],
        'related': ['flutter_complete', 'react_complete', 'javascript_fundamentals']
    },
    {
        'id': 'firebase_flutter',
        'title': 'Firebase with Flutter',
        'category': 'Mobile Development',
        'tags': ['Firebase', 'Flutter', 'Backend', 'Authentication', 'Database'],
        'related': ['flutter_complete', 'dart_fundamentals', 'mongodb_database']
    },
    {
        'id': 'swift_ios',
        'title': 'iOS Development with Swift',
        'category': 'Mobile Development',
        'tags': ['Swift', 'iOS', 'Apple', 'Xcode', 'Mobile'],
        'related': ['flutter_complete', 'react_native_complete', 'kotlin_android']
    },
    {
        'id': 'kotlin_android',
        'title': 'Android Development with Kotlin',
        'category': 'Mobile Development',
        'tags': ['Kotlin', 'Android', 'Mobile', 'Jetpack'],
        'related': ['flutter_complete', 'react_native_complete', 'swift_ios', 'java_fundamentals']
    },

    # =========================================================================
    # BLOCKCHAIN COURSES
    # =========================================================================
    {
        'id': 'blockchain_fundamentals',
        'title': 'Blockchain Fundamentals',
        'category': 'Blockchain',
        'tags': ['Blockchain', 'Cryptocurrency', 'Distributed', 'Web3'],
        'related': ['solidity_smart_contracts', 'ethereum_development', 'web3_development', 'defi_complete']
    },
    {
        'id': 'solidity_smart_contracts',
        'title': 'Solidity Smart Contract Development',
        'category': 'Blockchain',
        'tags': ['Solidity', 'Smart Contracts', 'Ethereum', 'DApps'],
        'related': ['blockchain_fundamentals', 'ethereum_development', 'web3_development', 'javascript_fundamentals']
    },
    {
        'id': 'ethereum_development',
        'title': 'Ethereum DApp Development',
        'category': 'Blockchain',
        'tags': ['Ethereum', 'DApps', 'Web3', 'Solidity', 'Truffle'],
        'related': ['blockchain_fundamentals', 'solidity_smart_contracts', 'web3_development', 'react_complete']
    },
    {
        'id': 'web3_development',
        'title': 'Web3 Development Complete',
        'category': 'Blockchain',
        'tags': ['Web3', 'JavaScript', 'Ethereum', 'DeFi', 'NFT'],
        'related': ['blockchain_fundamentals', 'solidity_smart_contracts', 'javascript_fundamentals', 'react_complete']
    },
    {
        'id': 'defi_complete',
        'title': 'DeFi Development Masterclass',
        'category': 'Blockchain',
        'tags': ['DeFi', 'Blockchain', 'Smart Contracts', 'Yield', 'Liquidity'],
        'related': ['blockchain_fundamentals', 'solidity_smart_contracts', 'ethereum_development']
    },
    {
        'id': 'nft_development',
        'title': 'NFT Development & Marketplaces',
        'category': 'Blockchain',
        'tags': ['NFT', 'Blockchain', 'Smart Contracts', 'IPFS', 'OpenSea'],
        'related': ['solidity_smart_contracts', 'ethereum_development', 'web3_development']
    },

    # =========================================================================
    # DATA SCIENCE & ML COURSES
    # =========================================================================
    {
        'id': 'python_fundamentals',
        'title': 'Python Programming Fundamentals',
        'category': 'Data Science',
        'tags': ['Python', 'Programming', 'OOP', 'Scripting'],
        'related': ['data_science_python', 'machine_learning_complete', 'django_web', 'deep_learning_tensorflow']
    },
    {
        'id': 'data_science_python',
        'title': 'Data Science with Python',
        'category': 'Data Science',
        'tags': ['Python', 'Data Science', 'Pandas', 'NumPy', 'Visualization'],
        'related': ['python_fundamentals', 'machine_learning_complete', 'deep_learning_tensorflow', 'sql_database']
    },
    {
        'id': 'machine_learning_complete',
        'title': 'Machine Learning Complete Course',
        'category': 'Data Science',
        'tags': ['Machine Learning', 'Python', 'Scikit-learn', 'AI', 'Statistics'],
        'related': ['python_fundamentals', 'data_science_python', 'deep_learning_tensorflow', 'ai_fundamentals']
    },
    {
        'id': 'deep_learning_tensorflow',
        'title': 'Deep Learning with TensorFlow',
        'category': 'Data Science',
        'tags': ['Deep Learning', 'TensorFlow', 'Neural Networks', 'Python', 'AI'],
        'related': ['machine_learning_complete', 'python_fundamentals', 'ai_fundamentals', 'computer_vision']
    },
    {
        'id': 'ai_fundamentals',
        'title': 'Artificial Intelligence Fundamentals',
        'category': 'Data Science',
        'tags': ['AI', 'Machine Learning', 'Deep Learning', 'NLP', 'Computer Vision'],
        'related': ['machine_learning_complete', 'deep_learning_tensorflow', 'python_fundamentals']
    },
    {
        'id': 'computer_vision',
        'title': 'Computer Vision with OpenCV',
        'category': 'Data Science',
        'tags': ['Computer Vision', 'OpenCV', 'Python', 'Deep Learning', 'Image Processing'],
        'related': ['deep_learning_tensorflow', 'machine_learning_complete', 'python_fundamentals']
    },

    # =========================================================================
    # BACKEND & DATABASES COURSES
    # =========================================================================
    {
        'id': 'django_web',
        'title': 'Django Web Development',
        'category': 'Backend',
        'tags': ['Django', 'Python', 'Backend', 'Web', 'REST API'],
        'related': ['python_fundamentals', 'flask_api', 'postgresql_database', 'react_complete']
    },
    {
        'id': 'flask_api',
        'title': 'Flask REST API Development',
        'category': 'Backend',
        'tags': ['Flask', 'Python', 'REST API', 'Backend', 'Microservices'],
        'related': ['python_fundamentals', 'django_web', 'mongodb_database']
    },
    {
        'id': 'java_fundamentals',
        'title': 'Java Programming Fundamentals',
        'category': 'Backend',
        'tags': ['Java', 'OOP', 'Programming', 'Backend'],
        'related': ['spring_boot', 'kotlin_android', 'python_fundamentals']
    },
    {
        'id': 'spring_boot',
        'title': 'Spring Boot Complete Guide',
        'category': 'Backend',
        'tags': ['Spring Boot', 'Java', 'Backend', 'Microservices', 'REST API'],
        'related': ['java_fundamentals', 'postgresql_database', 'docker_kubernetes']
    },
    {
        'id': 'mongodb_database',
        'title': 'MongoDB - The Complete Guide',
        'category': 'Backend',
        'tags': ['MongoDB', 'NoSQL', 'Database', 'Backend'],
        'related': ['nodejs_backend', 'python_fundamentals', 'flask_api']
    },
    {
        'id': 'postgresql_database',
        'title': 'PostgreSQL Masterclass',
        'category': 'Backend',
        'tags': ['PostgreSQL', 'SQL', 'Database', 'Backend'],
        'related': ['django_web', 'spring_boot', 'sql_database']
    },
    {
        'id': 'sql_database',
        'title': 'SQL & Database Design',
        'category': 'Backend',
        'tags': ['SQL', 'Database', 'MySQL', 'Design', 'Backend'],
        'related': ['postgresql_database', 'data_science_python', 'django_web']
    },

    # =========================================================================
    # DEVOPS & CLOUD COURSES
    # =========================================================================
    {
        'id': 'docker_kubernetes',
        'title': 'Docker & Kubernetes Complete',
        'category': 'DevOps',
        'tags': ['Docker', 'Kubernetes', 'DevOps', 'Containers', 'Orchestration'],
        'related': ['aws_cloud', 'linux_administration', 'spring_boot', 'nodejs_backend']
    },
    {
        'id': 'aws_cloud',
        'title': 'AWS Cloud Practitioner to Solutions Architect',
        'category': 'DevOps',
        'tags': ['AWS', 'Cloud', 'DevOps', 'Infrastructure', 'Serverless'],
        'related': ['docker_kubernetes', 'linux_administration', 'gcp_cloud']
    },
    {
        'id': 'gcp_cloud',
        'title': 'Google Cloud Platform Complete',
        'category': 'DevOps',
        'tags': ['GCP', 'Cloud', 'DevOps', 'Firebase', 'BigQuery'],
        'related': ['aws_cloud', 'docker_kubernetes', 'firebase_flutter']
    },
    {
        'id': 'linux_administration',
        'title': 'Linux System Administration',
        'category': 'DevOps',
        'tags': ['Linux', 'DevOps', 'Shell', 'System Admin', 'Servers'],
        'related': ['docker_kubernetes', 'aws_cloud', 'cybersecurity_fundamentals']
    },

    # =========================================================================
    # DESIGN COURSES
    # =========================================================================
    {
        'id': 'ui_ux_design',
        'title': 'UI/UX Design Masterclass',
        'category': 'Design',
        'tags': ['UI', 'UX', 'Design', 'Figma', 'User Research'],
        'related': ['figma_complete', 'html_css_modern', 'flutter_complete', 'react_complete']
    },
    {
        'id': 'figma_complete',
        'title': 'Figma - UI Design Tool Complete',
        'category': 'Design',
        'tags': ['Figma', 'UI Design', 'Prototyping', 'Design System'],
        'related': ['ui_ux_design', 'html_css_modern', 'react_complete']
    },
    {
        'id': 'graphic_design',
        'title': 'Graphic Design Essentials',
        'category': 'Design',
        'tags': ['Graphic Design', 'Photoshop', 'Illustrator', 'Branding'],
        'related': ['ui_ux_design', 'figma_complete', 'video_editing']
    },
    {
        'id': 'video_editing',
        'title': 'Video Editing with Premiere Pro',
        'category': 'Design',
        'tags': ['Video Editing', 'Premiere Pro', 'After Effects', 'Content Creation'],
        'related': ['graphic_design', 'photography_complete']
    },
    {
        'id': 'photography_complete',
        'title': 'Photography Masterclass',
        'category': 'Design',
        'tags': ['Photography', 'Lightroom', 'Camera', 'Editing'],
        'related': ['video_editing', 'graphic_design']
    },

    # =========================================================================
    # CYBERSECURITY COURSES
    # =========================================================================
    {
        'id': 'cybersecurity_fundamentals',
        'title': 'Cybersecurity Fundamentals',
        'category': 'Cybersecurity',
        'tags': ['Cybersecurity', 'Security', 'Networking', 'Ethical Hacking'],
        'related': ['ethical_hacking', 'linux_administration', 'network_security']
    },
    {
        'id': 'ethical_hacking',
        'title': 'Ethical Hacking Complete Course',
        'category': 'Cybersecurity',
        'tags': ['Ethical Hacking', 'Penetration Testing', 'Kali Linux', 'Security'],
        'related': ['cybersecurity_fundamentals', 'linux_administration', 'network_security']
    },
    {
        'id': 'network_security',
        'title': 'Network Security & Firewalls',
        'category': 'Cybersecurity',
        'tags': ['Network Security', 'Firewall', 'VPN', 'Security'],
        'related': ['cybersecurity_fundamentals', 'ethical_hacking', 'linux_administration']
    },

    # =========================================================================
    # BUSINESS COURSES
    # =========================================================================
    {
        'id': 'product_management',
        'title': 'Product Management Complete',
        'category': 'Business',
        'tags': ['Product Management', 'Agile', 'Scrum', 'Strategy'],
        'related': ['agile_scrum', 'ui_ux_design', 'startup_fundamentals']
    },
    {
        'id': 'agile_scrum',
        'title': 'Agile & Scrum Masterclass',
        'category': 'Business',
        'tags': ['Agile', 'Scrum', 'Project Management', 'Sprint'],
        'related': ['product_management', 'startup_fundamentals']
    },
    {
        'id': 'startup_fundamentals',
        'title': 'Startup Fundamentals',
        'category': 'Business',
        'tags': ['Startup', 'Entrepreneurship', 'Business', 'MVP'],
        'related': ['product_management', 'agile_scrum', 'digital_marketing']
    },
    {
        'id': 'digital_marketing',
        'title': 'Digital Marketing Complete',
        'category': 'Business',
        'tags': ['Digital Marketing', 'SEO', 'Social Media', 'Ads'],
        'related': ['startup_fundamentals', 'graphic_design']
    },
]


# =============================================================================
# FEATURE ENCODING FUNCTIONS
# =============================================================================
# The MLP needs numbers, not text!
# We convert categories and tags into numerical vectors.
# =============================================================================

def build_feature_encoders(courses):
    """
    Build encoders to convert text to numbers.
    
    Creates mappings like:
    - 'Web Development' → 0
    - 'Mobile Development' → 1
    - 'JavaScript' tag → 0
    - 'Python' tag → 1
    """
    # Get unique categories and tags
    categories = sorted(set(c['category'] for c in courses))
    all_tags = sorted(set(tag for c in courses for tag in c['tags']))
    
    # Create index mappings
    category_to_idx = {cat: idx for idx, cat in enumerate(categories)}
    tag_to_idx = {tag: idx for idx, tag in enumerate(all_tags)}
    course_to_idx = {c['id']: idx for idx, c in enumerate(courses)}
    
    return {
        'categories': categories,
        'tags': all_tags,
        'category_to_idx': category_to_idx,
        'tag_to_idx': tag_to_idx,
        'course_to_idx': course_to_idx,
        'idx_to_course': {idx: c['id'] for idx, c in enumerate(courses)},
        'num_categories': len(categories),
        'num_tags': len(all_tags),
        'num_courses': len(courses)
    }


def encode_course_features(course, encoders):
    """
    Encode a course into a feature vector (array of numbers).
    
    Example: "JavaScript Fundamentals" becomes:
    - Category: [1,0,0,0,0,0,0,0,0,0]  (Web Development = position 0)
    - Tags: [0,1,0,0,1,0,0,0,1,0,...]  (JavaScript=1, Frontend=1, ES6=1)
    - Combined: [1,0,0,...,0,1,0,0,1,0,0,0,1,0,...]
    """
    # Category: one-hot encoding (only ONE position is 1)
    category_vec = np.zeros(encoders['num_categories'], dtype=np.float32)
    category_idx = encoders['category_to_idx'].get(course['category'], 0)
    category_vec[category_idx] = 1.0
    
    # Tags: multi-hot encoding (MULTIPLE positions can be 1)
    tag_vec = np.zeros(encoders['num_tags'], dtype=np.float32)
    for tag in course['tags']:
        if tag in encoders['tag_to_idx']:
            tag_vec[encoders['tag_to_idx'][tag]] = 1.0
    
    # Concatenate category + tags into one big vector
    return np.concatenate([category_vec, tag_vec])


def create_training_data(courses, encoders):
    """
    Create training pairs from course relationships.
    
    For each pair of courses (A, B), we assign a similarity score:
    - 1.0 = They are in each other's 'related' list (most similar)
    - 0.6 = Same category but not directly related
    - 0.4 = Different category but share 2+ tags
    - 0.2 = Different category but share 1 tag
    - 0.0 = No relationship at all
    """
    # First, encode all courses into feature vectors
    course_features = []
    for course in courses:
        features = encode_course_features(course, encoders)
        course_features.append(features)
    
    course_features = np.array(course_features, dtype=np.float32)
    
    # Create pairs: (course1_idx, course2_idx, similarity_score)
    pairs_course1 = []
    pairs_course2 = []
    labels = []
    
    for i, course in enumerate(courses):
        for j, other_course in enumerate(courses):
            if i == j:
                continue  # Skip comparing course to itself
            
            pairs_course1.append(i)
            pairs_course2.append(j)
            
            # Determine similarity score based on relationship
            if other_course['id'] in course.get('related', []):
                # Directly related courses (in each other's 'related' list)
                labels.append(1.0)
            elif other_course['category'] == course['category']:
                # Same category but not directly related
                labels.append(0.6)
            else:
                # Check for tag overlap
                common_tags = set(course['tags']) & set(other_course['tags'])
                if len(common_tags) >= 2:
                    labels.append(0.4)
                elif len(common_tags) == 1:
                    labels.append(0.2)
                else:
                    labels.append(0.0)
    
    return (
        course_features,
        np.array(pairs_course1, dtype=np.int32),
        np.array(pairs_course2, dtype=np.int32),
        np.array(labels, dtype=np.float32)
    )


# =============================================================================
# MLP MODEL ARCHITECTURE
# =============================================================================

def build_similarity_model(num_courses, feature_dim, embedding_dim=64):
    """
    Build an MLP model that learns course embeddings and predicts similarity.
    
    ARCHITECTURE:
    ┌────────────────────┐     ┌────────────────────┐
    │ Course 1 Features  │     │ Course 2 Features  │
    └─────────┬──────────┘     └─────────┬──────────┘
              │                          │
              ▼                          ▼
    ┌─────────────────────────────────────────────┐
    │    Shared Embedding Network (MLP)           │
    │    Dense(128) → Dropout → Dense(64) → L2   │
    └─────────┬──────────────────────┬────────────┘
              │                      │
              ▼                      ▼
    ┌──────────────┐          ┌──────────────┐
    │ Embedding 1  │          │ Embedding 2  │
    │  (64-dim)    │          │  (64-dim)    │
    └──────┬───────┘          └──────┬───────┘
           │                         │
           └───────────┬─────────────┘
                       ▼
              ┌─────────────────┐
              │  Dot Product    │  ← Cosine Similarity
              │    + Sigmoid    │
              └────────┬────────┘
                       ▼
              ┌─────────────────┐
              │ Similarity 0-1  │
              └─────────────────┘
    """
    # Course feature inputs
    course1_input = tf.keras.layers.Input(shape=(feature_dim,), name='course1_features')
    course2_input = tf.keras.layers.Input(shape=(feature_dim,), name='course2_features')
    
    # Shared embedding network (MLP)
    # Both courses go through the SAME network (shared weights)
    embedding_network = tf.keras.Sequential([
        tf.keras.layers.Dense(128, activation='relu', name='embed_dense1'),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(64, activation='relu', name='embed_dense2'),
        tf.keras.layers.Dense(embedding_dim, activation=None, name='embedding'),
        tf.keras.layers.Lambda(lambda x: tf.nn.l2_normalize(x, axis=1))  # L2 normalize for cosine similarity
    ], name='embedding_network')
    
    # Get embeddings for both courses
    embedding1 = embedding_network(course1_input)
    embedding2 = embedding_network(course2_input)
    
    # Compute similarity (dot product of normalized vectors = cosine similarity)
    similarity = tf.keras.layers.Dot(axes=1, normalize=False)([embedding1, embedding2])
    
    # Map to [0, 1] range with sigmoid
    output = tf.keras.layers.Activation('sigmoid')(similarity)
    
    # Build model
    model = tf.keras.Model(
        inputs=[course1_input, course2_input],
        outputs=output,
        name='course_similarity_model'
    )
    
    return model, embedding_network


# =============================================================================
# INFERENCE MODEL (for TFLite export)
# =============================================================================

def build_inference_model(embedding_network, feature_dim):
    """
    Build a simpler model for TFLite that:
    - Takes a single course's features
    - Outputs its embedding vector (64 numbers)
    
    In Flutter, we'll:
    1. Compute embeddings for all courses at startup
    2. When user views a course, find courses with similar embeddings
    3. Recommend top 5 most similar courses
    """
    course_input = tf.keras.layers.Input(shape=(feature_dim,), name='course_features')
    embedding = embedding_network(course_input)
    
    inference_model = tf.keras.Model(
        inputs=course_input,
        outputs=embedding,
        name='course_embedding_model'
    )
    
    return inference_model


# =============================================================================
# MAIN TRAINING FUNCTION
# =============================================================================

def main():
    print("=" * 60)
    print("Course Similarity MLP Training")
    print("=" * 60)
    
    # STEP 1: Build encoders
    print("\n1. Building feature encoders...")
    encoders = build_feature_encoders(COURSES)
    print(f"   - {encoders['num_courses']} courses")
    print(f"   - {encoders['num_categories']} categories")
    print(f"   - {encoders['num_tags']} unique tags")
    
    # STEP 2: Create training data
    print("\n2. Creating training data...")
    course_features, pairs_c1, pairs_c2, labels = create_training_data(COURSES, encoders)
    feature_dim = course_features.shape[1]
    print(f"   - Feature dimension: {feature_dim}")
    print(f"   - Training pairs: {len(labels)}")
    print(f"   - Positive pairs (similarity > 0.5): {np.sum(labels > 0.5)}")
    
    # Prepare training inputs
    X1 = course_features[pairs_c1]  # Course 1 features for each pair
    X2 = course_features[pairs_c2]  # Course 2 features for each pair
    y = labels                       # Similarity scores
    
    # Shuffle the data
    indices = np.random.permutation(len(y))
    X1, X2, y = X1[indices], X2[indices], y[indices]
    
    # STEP 3: Split into train/test
    split_idx = int(0.8 * len(y))
    X1_train, X1_test = X1[:split_idx], X1[split_idx:]
    X2_train, X2_test = X2[:split_idx], X2[split_idx:]
    y_train, y_test = y[:split_idx], y[split_idx:]
    
    print(f"   - Train samples: {len(y_train)}")
    print(f"   - Test samples: {len(y_test)}")
    
    # STEP 4: Build model
    print("\n3. Building MLP model...")
    model, embedding_network = build_similarity_model(
        num_courses=encoders['num_courses'],
        feature_dim=feature_dim,
        embedding_dim=64
    )
    
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss='mse',
        metrics=['mae']
    )
    
    model.summary()
    
    # STEP 5: Train
    print("\n4. Training model...")
    history = model.fit(
        [X1_train, X2_train],
        y_train,
        validation_data=([X1_test, X2_test], y_test),
        epochs=50,
        batch_size=64,
        verbose=1
    )
    
    print(f"\n   Final train loss: {history.history['loss'][-1]:.4f}")
    print(f"   Final val loss: {history.history['val_loss'][-1]:.4f}")
    
    # STEP 6: Build inference model for TFLite
    print("\n5. Building inference model for TFLite...")
    inference_model = build_inference_model(embedding_network, feature_dim)
    inference_model.summary()
    
    # STEP 7: Precompute all course embeddings
    print("\n6. Computing course embeddings...")
    all_embeddings = inference_model.predict(course_features)
    print(f"   - Embeddings shape: {all_embeddings.shape}")  # (num_courses, 64)
    
    # STEP 8: Test similarity predictions
    print("\n7. Testing similarity predictions...")
    test_courses = ['javascript_fundamentals', 'flutter_complete', 'blockchain_fundamentals']
    
    for test_id in test_courses:
        test_idx = encoders['course_to_idx'][test_id]
        test_embedding = all_embeddings[test_idx]
        
        # Compute similarities using dot product
        similarities = np.dot(all_embeddings, test_embedding)
        top_indices = np.argsort(similarities)[::-1][1:6]  # Top 5, excluding self
        
        print(f"\n   '{test_id}' similar to:")
        for idx in top_indices:
            course_id = encoders['idx_to_course'][idx]
            sim_score = similarities[idx]
            print(f"      - {course_id}: {sim_score:.3f}")
    
    # STEP 9: Convert to TFLite
    print("\n8. Converting to TFLite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(inference_model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    
    # Save TFLite model
    os.makedirs('../assets/model', exist_ok=True)
    tflite_path = '../assets/model/course_similarity_model.tflite'
    with open(tflite_path, 'wb') as f:
        f.write(tflite_model)
    print(f"   Saved TFLite model to {tflite_path}")
    print(f"   Model size: {len(tflite_model) / 1024:.2f} KB")
    
    # STEP 10: Save encoders and embeddings
    print("\n9. Saving encoders and embeddings...")
    
    # Prepare course data for JSON
    courses_data = []
    for i, course in enumerate(COURSES):
        courses_data.append({
            'id': course['id'],
            'title': course['title'],
            'category': course['category'],
            'tags': course['tags'],
            'embedding': all_embeddings[i].tolist()  # 64-number embedding
        })
    
    encoder_data = {
        'courses': courses_data,
        'categories': encoders['categories'],
        'tags': encoders['tags'],
        'category_to_idx': encoders['category_to_idx'],
        'tag_to_idx': encoders['tag_to_idx'],
        'feature_dim': feature_dim,
        'embedding_dim': 64
    }
    
    encoder_path = '../assets/model/course_similarity_encoders.json'
    with open(encoder_path, 'w') as f:
        json.dump(encoder_data, f, indent=2)
    print(f"   Saved encoders to {encoder_path}")
    
    print("\n" + "=" * 60)
    print("Training complete!")
    print("=" * 60)


if __name__ == '__main__':
    main()
