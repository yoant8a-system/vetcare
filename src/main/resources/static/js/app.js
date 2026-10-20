// Comportamientos comunes de la plantilla
document.addEventListener('DOMContentLoaded', () => {
    // Titulo de la barra superior = titulo de la pagina
    const t = document.querySelector('.topbar .titulo');
    if (t) {
        t.textContent = document.title.replace(' - VetCare', '');
    }

    // Menu lateral en pantallas chicas
    const btn = document.querySelector('.btn-menu');
    const sidebar = document.querySelector('.sidebar');
    if (btn && sidebar) {
        btn.addEventListener('click', () => sidebar.classList.toggle('abierto'));
    }

    // Confirmacion antes de acciones destructivas: <form data-confirmar="¿Seguro?">
    document.querySelectorAll('form[data-confirmar]').forEach(f => {
        f.addEventListener('submit', e => {
            if (!confirm(f.dataset.confirmar)) {
                e.preventDefault();
            }
        });
    });

    // Los mensajes verdes se ocultan solos
    document.querySelectorAll('.alert-success').forEach(a => {
        setTimeout(() => bootstrap.Alert.getOrCreateInstance(a).close(), 6000);
    });

    // Activar la pestaña indicada en la URL (#vacunas)
    if (location.hash) {
        const tab = document.querySelector(`[data-bs-target="${location.hash}"]`);
        if (tab) {
            bootstrap.Tab.getOrCreateInstance(tab).show();
        }
    }
});

// Imagen segun la especie (perro, gato, conejo, ave)
function imagenEspecie(especie) {
    const e = (especie || '').toLowerCase();
    return '/img/' + (['perro', 'gato', 'conejo', 'ave'].includes(e) ? e : 'logo') + '.svg';
}
