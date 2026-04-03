-- Seed de reglas de enrutamiento
INSERT INTO route_rules (rule_name, condition_field, condition_value, destination_rail, priority, description) VALUES
('pix_key_to_pix',        'alias.type',           'PIX_KEY',     'PIX',    1, 'Alias PIX_KEY enruta a riel PIX'),
('clabe_to_spei',         'alias.type',           'CLABE',       'SPEI',   1, 'Alias CLABE enruta a riel SPEI'),
('llave_breb_to_breb',    'alias.type',           'LLAVE_BREB',  'BRE_B',  1, 'Alias LLAVE_BREB enruta a riel Bre-B Colombia'),
('country_br_to_pix',     'destination_country',  'BR',          'PIX',    2, 'País BR refuerza riel PIX'),
('country_mx_to_spei',    'destination_country',  'MX',          'SPEI',   2, 'País MX refuerza riel SPEI'),
('country_co_to_breb',    'destination_country',  'CO',          'BRE_B',  2, 'País CO enruta a riel Bre-B Colombia'),
('phone_co_to_breb',      'alias.value_prefix',   '+57',         'BRE_B',  3, 'Número celular colombiano (+57) enruta a Bre-B'),
('fallback_unavailable',  'availability',         'DOWN',        'FAILED', 9, 'Riel no disponible = FAILED');
