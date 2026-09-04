# ADR-002 — Supabase + PostgreSQL + Auth + RLS

Status: Accepted

## Context

Se necesita un backend gestionado con base de datos, autenticación y aislamiento estricto entre usuarios.

## Decision

Usar Supabase administrado (PostgreSQL + Auth + RLS), región São Paulo (sa-east-1).

## Consequences

- RLS es el mecanismo de aislamiento entre usuarios.
- El cliente nunca es una frontera confiable para autorización.
