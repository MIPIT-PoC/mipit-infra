-- Seed de reglas de enrutamiento
INSERT INTO route_rules (rule_name, condition_field, condition_value, destination_rail, priority, description) VALUES
('pix_key_to_pix',        'alias.type',           'PIX_KEY', 'PIX',  1, 'Alias PIX_KEY enruta a riel PIX'),
('clabe_to_spei',         'alias.type',           'CLABE',   'SPEI', 1, 'Alias CLABE enruta a riel SPEI'),
('country_br_to_pix',     'destination_country',  'BR',      'PIX',  2, 'País BR refuerza riel PIX'),
('country_mx_to_spei',    'destination_country',  'MX',      'SPEI', 2, 'País MX refuerza riel SPEI'),
('fallback_unavailable',  'availability',         'DOWN',    'FAILED', 3, 'Riel no disponible = FAILED');
