#!/usr/bin/env python3
"""
Initialize database by importing models
This creates the database with all the latest schema
"""

import uuid
from datetime import datetime
from database import Base, engine
from sqlalchemy.orm import sessionmaker

if __name__ == "__main__":
    print("Initializing database with new schema...")
    try:
        # Import models to register them with Base
        from models import Owner, Todo, Project
        
        # Create all tables
        Base.metadata.create_all(bind=engine)
        
        print("✅ Database initialized successfully!")
        print("\nSchema created with these Todo fields:")
        print("  - Basic: id, owner_id, title, description, status, priority, due_date")
        print("  - Phase 1 (AI-ready): estimated_hours, complexity, project, category")
        print("  - Phase 2 (Execution): actual_hours, dependencies, required_skills")
        print("  - Completion: completed_at, completed_content")
        print("  - Timestamps: created_at, updated_at")
        
        # Create default Owner and Project
        Session = sessionmaker(bind=engine)
        session = Session()
        
        # Check if default owner already exists
        default_owner = session.query(Owner).filter(Owner.id == "default-user").first()
        
        if not default_owner:
            print("\n📝 Creating default owner...")
            default_owner = Owner(
                id="default-user",
                name="Default User",
                email="default@todomanagement.local",
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            session.add(default_owner)
            session.commit()
            print("   ✅ Default owner created: default-user")
        
        # Check if default project already exists
        default_project = session.query(Project).filter(
            Project.owner_id == "default-user",
            Project.name == "Default Project"
        ).first()
        
        if not default_project:
            print("📁 Creating default project...")
            default_project = Project(
                id=str(uuid.uuid4()),
                owner_id="default-user",
                name="Default Project",
                description="Default project for organizing todos",
                status="active",
                priority="medium",
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            session.add(default_project)
            session.commit()
            print("   ✅ Default project created: Default Project")
        
        session.close()
        
        print("\n🎉 Database initialization complete!")
        print("   Default owner: default-user (default@todomanagement.local)")
        print("   Default project: Default Project")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
