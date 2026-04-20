// Chart.js integration
// chart.js - For complaints analytics charts

function renderStatusChart(pending, solved) 
{
    const ctx1 = document.getElementById('statusChart').getContext('2d');
    new Chart(ctx1, {
        type: 'doughnut',
        data: {
            labels: ['Pending', 'Solved'],
            datasets: [{
                label: 'Complaint Status',
                data: [pending, solved],
                backgroundColor: ['#ff6384', '#36a2eb']
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: {
                    position: 'top',
                },
                title: {
                    display: true,
                    text: 'Complaint Status Analytics'
                }
            }
        }
    });
}


function renderCategoryChart(categories, counts) 
{
    const ctx2 = document.getElementById('categoryChart').getContext('2d');
    new Chart(ctx2, {
        type: 'bar',
        data: {
            labels: categories,
            datasets: [{
                label: 'Complaints by Category',
                data: counts,
                backgroundColor: '#ff9f40'
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: {
                    display: false
                },
                title: 
                {
                    display: true,
                    text: 'Complaints per Category'
                }
            }
        }
    });
}