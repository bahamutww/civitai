CREATE OR REPLACE FUNCTION create_job_queue_record(entityId INTEGER, entityType text, type text)
RETURNS VOID AS $job_queue_record$
BEGIN
  INSERT INTO "JobQueue" ("entityId", "entityType", "type")
  VALUES (entityId, entityType::"EntityType", type::"JobQueueType")
  ON CONFLICT DO NOTHING;
END;
$job_queue_record$ LANGUAGE plpgsql;
---

-- IMAGE TRIGGER
CREATE OR REPLACE FUNCTION update_image_nsfw_level()
RETURNS TRIGGER AS $image_nsfw_level$
BEGIN
  IF (TG_OP = 'DELETE') THEN

    IF (OLD."postId" IS NOT NULL AND OLD."nsfwLevel" != 0) THEN
      PERFORM create_job_queue_record(OLD."postId", 'Post', 'UpdateNsfwLevel');
    END IF;

    PERFORM create_job_queue_record(OLD.id, 'Image', 'CleanUp');

  ELSIF (NEW."nsfwLevel" != OLD."nsfwLevel") THEN
    PERFORM create_job_queue_record(NEW.id, 'Image', 'UpdateNsfwLevel');
  END IF;
  RETURN NULL;
END;
$image_nsfw_level$ LANGUAGE plpgsql;
---
CREATE OR REPLACE TRIGGER image_nsfw_level_change
AFTER UPDATE OF "nsfwLevel" OR DELETE ON "Image"
FOR EACH ROW
EXECUTE FUNCTION update_image_nsfw_level();


-- POST TRIGGER
CREATE OR REPLACE FUNCTION update_post_nsfw_level()
RETURNS TRIGGER AS $post_nsfw_level$
BEGIN
  IF (TG_OP = 'DELETE') THEN

    IF (OLD."modelVersionId" IS NOT NULL AND p."publishedAt" IS NOT NULL) THEN
      PERFORM create_job_queue_record(OLD."modelVersionId", 'ModelVersion', 'UpdateNsfwLevel');
    END IF;

    PERFORM create_job_queue_record(OLD.id, 'Post', 'CleanUp');

  ELSIF (NEW."publishedAt" IS NOT NULL and OLD."nsfwLevel" != 0) THEN
    PERFORM create_job_queue_record(NEW.id, 'Post', 'UpdateNsfwLevel');
  END IF;
  RETURN NULL;
END;
$post_nsfw_level$ LANGUAGE plpgsql;
---
CREATE OR REPLACE TRIGGER post_nsfw_level_change
AFTER UPDATE OF "publishedAt" OR DELETE ON "Post"
FOR EACH ROW
EXECUTE FUNCTION update_post_nsfw_level();


-- MODEL VERSION TRIGGER
CREATE OR REPLACE FUNCTION update_model_version_nsfw_level()
RETURNS TRIGGER AS $model_version_nsfw_level$
BEGIN
  IF (TG_OP = 'DELETE') THEN
    PERFORM create_job_queue_record(OLD."modelId", 'Model', 'UpdateNsfwLevel');
  ELSIF (NEW.status = 'Published' AND OLD."nsfwLevel" != 0) THEN
    PERFORM create_job_queue_record(NEW.id, 'ModelVersion', 'UpdateNsfwLevel');
  END IF;
  RETURN NULL;
END;
$model_version_nsfw_level$ LANGUAGE plpgsql;
---
CREATE OR REPLACE TRIGGER model_version_nsfw_level_change
AFTER UPDATE OF "status" OR DELETE ON "ModelVersion"
FOR EACH ROW
EXECUTE FUNCTION update_model_version_nsfw_level();


-- MODEL TRIGGER
CREATE OR REPLACE FUNCTION update_model_nsfw_level()
RETURNS TRIGGER AS $model_nsfw_level$
BEGIN
  IF (TG_OP = 'DELETE') THEN
    PERFORM create_job_queue_record(OLD.id, 'Model', 'CleanUp');
  ELSIF (NEW.status = 'Published' AND OLD."nsfwLevel" != 0) THEN
    PERFORM create_job_queue_record(OLD."id", 'Model', 'UpdateNsfwLevel');
  END IF;
  RETURN NULL;
END;
$model_nsfw_level$ LANGUAGE plpgsql;
---
CREATE OR REPLACE TRIGGER model_nsfw_level_change
AFTER UPDATE OF "status", "nsfw" OR DELETE ON "Model"
FOR EACH ROW
EXECUTE FUNCTION update_model_nsfw_level();


-- ARTICLE TRIGGER
CREATE OR REPLACE FUNCTION update_article_nsfw_level()
RETURNS TRIGGER AS $article_nsfw_level$
BEGIN
  IF (TG_OP = 'DELETE') THEN
    PERFORM create_job_queue_record(OLD.id, 'Article', 'CleanUp');
  ELSIF (NEW."publishedAt" IS NOT NULL AND OLD."nsfwLevel" != 0) THEN
    PERFORM create_job_queue_record(OLD."id", 'Article', 'UpdateNsfwLevel');
  END IF;
  RETURN NULL;
END;
$article_nsfw_level$ LANGUAGE plpgsql;
---
CREATE OR REPLACE TRIGGER article_nsfw_level_change
AFTER UPDATE OF "publishedAt", "userNsfwLevel" OR DELETE ON "Article"
FOR EACH ROW
EXECUTE FUNCTION update_article_nsfw_level();


-- COLLECTION ITEM TRIGGER
CREATE OR REPLACE FUNCTION update_collection_nsfw_level()
RETURNS TRIGGER AS $collection_nsfw_level$
BEGIN
  IF (TG_OP = 'DELETE') THEN
    PERFORM create_job_queue_record(OLD.id, 'Collection', 'UpdateNsfwLevel');
  ELSIF (TG_OP = 'UPDATE') THEN
    PERFORM create_job_queue_record(OLD."id", 'Collection', 'UpdateNsfwLevel');
  END IF;
  RETURN NULL;
END;
$collection_nsfw_level$ LANGUAGE plpgsql;
---
CREATE OR REPLACE TRIGGER collection_nsfw_level_change
AFTER UPDATE OR DELETE ON "CollectionItem"
FOR EACH ROW
EXECUTE FUNCTION update_collection_nsfw_level();


-- BOUNTY TRIGGER
CREATE OR REPLACE FUNCTION update_bounty_nsfw_level()
RETURNS TRIGGER AS $bounty_nsfw_level$
BEGIN
  PERFORM create_job_queue_record(NEW."id", 'Bounty', 'UpdateNsfwLevel');
  RETURN NULL;
END;
$bounty_nsfw_level$ LANGUAGE plpgsql;
---
CREATE OR REPLACE TRIGGER bounty_nsfw_level_change
AFTER UPDATE OF "nsfw" ON "Bounty"
FOR EACH ROW
EXECUTE FUNCTION update_bounty_nsfw_level();
