CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Audit: conversations
CREATE TABLE IF NOT EXISTS audit_conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    conversation_id UUID NOT NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    iterations INT NOT NULL DEFAULT 0,
    tools_called JSONB NOT NULL DEFAULT '{}',
    citations_count INT NOT NULL DEFAULT 0,
    web_results_count INT NOT NULL DEFAULT 0,
    prediction_label TEXT,
    error_count INT NOT NULL DEFAULT 0,
    tokens_used INT NOT NULL DEFAULT 0,
    firecrawl_cost_estimate_usd NUMERIC(10,4) NOT NULL DEFAULT 0.0000
);

CREATE INDEX IF NOT EXISTS idx_audit_conversations_user_id ON audit_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_conversations_ended_at ON audit_conversations(ended_at);

-- Audit: file uploads
CREATE TABLE IF NOT EXISTS audit_uploads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id UUID NOT NULL,
    uploaded_by UUID NOT NULL,
    file_name TEXT NOT NULL,
    file_type TEXT NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    total_chunks INT NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'pending',
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_audit_uploads_uploaded_by ON audit_uploads(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_audit_uploads_status ON audit_uploads(status);
