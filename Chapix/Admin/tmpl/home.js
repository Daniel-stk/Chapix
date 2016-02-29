google.charts.load('current', {'packages':['corechart']});
google.charts.setOnLoadCallback(drawCharts);

function drawCharts () {
    drawCustomersTotalChart();
    drawCustomersNewChurnedChart();
    drawRevenueChart();
 
    drawDomainsTotalChart();
    drawDomainsNewChart();
}

function drawCustomersTotalChart() {
    var data = google.visualization.arrayToDataTable([
        ['Fecha', '# de clientes','# Clientes activos'],
	[% FOREACH date=metrics %]
        ['[% date.date%]', [% date.customers_total %], [% date.customers_active %]][% IF !(loop.last) %],[% END %]
	[% END %]
    ]);
    
    var options = {
        title: '# de clientes',
	legend: 'none',
	colors: ['#64b5f6','#1a237e']
    };
    
    var chart = new google.visualization.AreaChart(document.getElementById('customers_total_div'));
    chart.draw(data, options);
}

function drawCustomersNewChurnedChart() {
    var data = google.visualization.arrayToDataTable([
        ['Fecha', 'Clientes nuevos','Clientes perdidos'],
	[% FOREACH date=metrics %]
        ['[% date.date%]', [% date.customers_new %], [% date.customers_churned %]][% IF !(loop.last) %],[% END %]
	[% END %]
    ]);
    
    var options = {
        title: '# Clientes nuevos VS Perdidos',
	legend: 'none',
	colors: ['#1a237e','#b71c1c']
    };
    
    var chart = new google.visualization.AreaChart(document.getElementById('customers_new_churned_div'));
    chart.draw(data, options);
}

function drawRevenueChart() {
    var data = google.visualization.arrayToDataTable([
        ['Fecha', 'Ingresos'],
	[% FOREACH date=metrics %]
        ['[% date.date%]', [% date.revenue %]][% IF !(loop.last) %],[% END %]
	[% END %]
    ]);
    
    var options = {
        title: '# Ingresos diarios',
	legend: 'none',
	colors: ['#9ccc65']
    };
    
    var chart = new google.visualization.AreaChart(document.getElementById('revenue_div'));
    chart.draw(data, options);
}

function drawDomainsTotalChart() {
    var data = google.visualization.arrayToDataTable([
        ['Fecha', '# cuentas','# Cuentas activas', '# Clientes'],
	[% FOREACH date=metrics %]
        ['[% date.date%]', [% date.domains_total %], [% date.domains_active %], [% date.customers_total %]][% IF !(loop.last) %],[% END %]
	[% END %]
    ]);
    
    var options = {
        title: '# Cuentas',
	legend: 'none',
	colors: ['#ffeb3b','#03a9f4','#8bc34a']
    };
    
    var chart = new google.visualization.AreaChart(document.getElementById('domains_total_div'));
    chart.draw(data, options);
}

function drawDomainsNewChart() {
    var data = google.visualization.arrayToDataTable([
        ['Fecha', '# nuevas cuentas'],
	[% FOREACH date=metrics %]
        ['[% date.date%]', [% date.domains_new %]][% IF !(loop.last) %],[% END %]
	[% END %]
    ]);
    
    var options = {
        title: '# Nuevas Cuentas',
	legend: 'none',
	colors: ['#8bc34a']
    };
    
    var chart = new google.visualization.AreaChart(document.getElementById('domains_new_div'));
    chart.draw(data, options);
}
