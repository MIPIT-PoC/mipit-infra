-- 013_seed_breb_mappings.sql
-- P04 — Seed mapping_table with Bre-B rows. Previously empty (only PIX and
-- SPEI had mappings), which forced the canonical→Bre-B path to be hard-coded
-- in code instead of table-driven like the other rails.

INSERT INTO mapping_table (rail, direction, source_field, target_field, transformation, validation_rule, notes)
VALUES
  -- Bre-B → canonical (TO_CANONICAL)
  ('BRE_B', 'TO_CANONICAL', 'idTransaccion',           'pmtId.endToEndId',           'truncate_35',  NULL, 'Bre-B txn ID up to 32 chars (4-dig entidad) or 36 (legacy 8-dig)'),
  ('BRE_B', 'TO_CANONICAL', 'fechaHora',               'grpHdr.creDtTm',             'copy',         'iso_8601', 'Bre-B emission time (Bogotá UTC-5)'),
  ('BRE_B', 'TO_CANONICAL', 'valor.original',          'amount.value',               'parse_decimal', NULL,      'COP integer or 2-decimal string'),
  ('BRE_B', 'TO_CANONICAL', 'pagador.nombre',          'debtor.name',                'truncate_140', 'len_0_140', NULL),
  ('BRE_B', 'TO_CANONICAL', 'pagador.codigoEntidad',   'origin.institutionCode',     'copy',         'len_4_or_8', 'Superfinanciera 4-dig or legacy 8-dig'),
  ('BRE_B', 'TO_CANONICAL', 'pagador.nit',             'debtor.taxId',               'copy',         'nit_format', NULL),
  ('BRE_B', 'TO_CANONICAL', 'pagador.cc',              'debtor.taxId',               'copy',         'cc_format',  NULL),
  ('BRE_B', 'TO_CANONICAL', 'pagador.tipoCuenta',      'debtor.accountType',         'copy',         NULL,         NULL),
  ('BRE_B', 'TO_CANONICAL', 'beneficiario.nombre',     'creditor.name',              'truncate_140', 'len_0_140',  NULL),
  ('BRE_B', 'TO_CANONICAL', 'beneficiario.codigoEntidad', 'destination.institutionCode', 'copy',      'len_4_or_8', NULL),
  ('BRE_B', 'TO_CANONICAL', 'llave',                   'alias.value',                'copy',         NULL,         NULL),
  ('BRE_B', 'TO_CANONICAL', 'tipoLlave',               'alias.subtype',              'copy',         NULL,         'CC/CE/NIT/PASAPORTE/TELEFONO/EMAIL/ALIAS'),
  ('BRE_B', 'TO_CANONICAL', 'concepto',                'remittanceInfo',             'truncate_140', 'len_0_140',  NULL),

  -- canonical → Bre-B (FROM_CANONICAL)
  ('BRE_B', 'FROM_CANONICAL', 'pmtId.endToEndId',          'idTransaccion',             'regenerate_if_invalid', 'breb_format', 'Regenerate if not Bre-B format'),
  ('BRE_B', 'FROM_CANONICAL', 'grpHdr.creDtTm',            'fechaHora',                 'copy',          NULL,         NULL),
  ('BRE_B', 'FROM_CANONICAL', 'amount.value',              'valor.original',            'cop_integer',   NULL,         'COP no centavos'),
  ('BRE_B', 'FROM_CANONICAL', 'debtor.name',               'pagador.nombre',            'truncate_140',  NULL,         NULL),
  ('BRE_B', 'FROM_CANONICAL', 'origin.institutionCode',    'pagador.codigoEntidad',     'copy',          'len_4_or_8', NULL),
  ('BRE_B', 'FROM_CANONICAL', 'debtor.taxId',              'pagador.nit_or_cc',         'route_by_format', NULL,       'Dash → NIT, plain digits → CC'),
  ('BRE_B', 'FROM_CANONICAL', 'creditor.name',             'beneficiario.nombre',       'truncate_140',  NULL,         NULL),
  ('BRE_B', 'FROM_CANONICAL', 'destination.institutionCode', 'beneficiario.codigoEntidad', 'copy',       'len_4_or_8', NULL),
  ('BRE_B', 'FROM_CANONICAL', 'alias.value',               'llave',                     'copy',          NULL,         NULL),
  ('BRE_B', 'FROM_CANONICAL', 'remittanceInfo',            'concepto',                  'truncate_140',  NULL,         NULL)
ON CONFLICT (rail, direction, source_field) DO NOTHING;
