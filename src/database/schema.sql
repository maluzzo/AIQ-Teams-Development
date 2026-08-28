-- AIQ Product Factory — Core state schema (section 14 of CLAUDE.md)
-- Tracks projects, runs, workflow steps, agent executions, documents, errors and token usage.

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Projects')
CREATE TABLE Projects (
    ProjectId       UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    Slug            NVARCHAR(100)    NOT NULL UNIQUE,
    Name            NVARCHAR(200)    NOT NULL,
    Idea            NVARCHAR(MAX)    NULL,
    Status          NVARCHAR(30)     NOT NULL DEFAULT 'Pending',
    CreatedAt       DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ProjectRuns')
CREATE TABLE ProjectRuns (
    RunId           UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    ProjectId       UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Projects(ProjectId),
    Status          NVARCHAR(30)     NOT NULL DEFAULT 'Pending', -- Pending/Running/Waiting/Completed/Failed/Cancelled
    CurrentStage    NVARCHAR(100)    NULL,
    StartedAt       DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),
    FinishedAt      DATETIME2        NULL
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'WorkflowSteps')
CREATE TABLE WorkflowSteps (
    StepId          UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    RunId           UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES ProjectRuns(RunId),
    StepName        NVARCHAR(100)    NOT NULL, -- e.g. AIQ-PF-02-MarketResearch
    Sequence        INT              NOT NULL,
    Status          NVARCHAR(30)     NOT NULL DEFAULT 'Pending',
    StartedAt       DATETIME2        NULL,
    FinishedAt      DATETIME2        NULL
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Agents')
CREATE TABLE Agents (
    AgentId         UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    AgentName       NVARCHAR(100)    NOT NULL UNIQUE, -- e.g. Research Agent, Strategy Agent
    Role            NVARCHAR(200)    NULL,
    DefaultProvider NVARCHAR(50)     NULL, -- openrouter/openai/anthropic/gemini
    DefaultModel    NVARCHAR(100)    NULL
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AgentRuns')
CREATE TABLE AgentRuns (
    AgentRunId      UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    StepId          UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES WorkflowSteps(StepId),
    AgentId         UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Agents(AgentId),
    Provider        NVARCHAR(50)     NULL,
    Model           NVARCHAR(100)    NULL,
    Status          NVARCHAR(30)     NOT NULL DEFAULT 'Pending',
    InputTokens     INT              NULL,
    OutputTokens    INT              NULL,
    CostEstimate    DECIMAL(10,4)    NULL,
    DurationMs      INT              NULL,
    StartedAt       DATETIME2        NULL,
    FinishedAt      DATETIME2        NULL
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Documents')
CREATE TABLE Documents (
    DocumentId      UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    ProjectId       UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Projects(ProjectId),
    RunId           UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES ProjectRuns(RunId),
    DocumentType    NVARCHAR(100)    NOT NULL, -- market-research.md, MASTER_SPEC.md, etc.
    FilePath        NVARCHAR(500)    NOT NULL,
    CreatedAt       DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Errors')
CREATE TABLE Errors (
    ErrorId         UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    RunId           UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES ProjectRuns(RunId),
    StepId          UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES WorkflowSteps(StepId),
    AgentRunId      UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES AgentRuns(AgentRunId),
    ErrorMessage    NVARCHAR(MAX)    NOT NULL,
    ErrorContext    NVARCHAR(MAX)    NULL,
    CreatedAt       DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TokensUsage')
CREATE TABLE TokensUsage (
    UsageId         UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    ProjectId       UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Projects(ProjectId),
    AgentRunId      UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES AgentRuns(AgentRunId),
    Provider        NVARCHAR(50)     NOT NULL,
    Model           NVARCHAR(100)    NOT NULL,
    InputTokens     INT              NOT NULL DEFAULT 0,
    OutputTokens    INT              NOT NULL DEFAULT 0,
    CostEstimate    DECIMAL(10,4)    NULL,
    CreatedAt       DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME()
);
GO
