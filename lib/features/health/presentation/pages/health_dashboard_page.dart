import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:viva_livre_app/features/health/presentation/health_bloc.dart';
import 'package:intl/intl.dart';

class HealthDashboardPage extends StatefulWidget {
  const HealthDashboardPage({super.key});

  @override
  State<HealthDashboardPage> createState() => _HealthDashboardPageState();
}

class _HealthDashboardPageState extends State<HealthDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<HealthBloc>().add(FetchHealthEntries());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seu Painel de Saúde'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Icon(Icons.monitor_heart_outlined, size: 80, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12),
            const Text(
              'Painel de Saúde',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Acompanhe seus sintomas e crises aqui.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tendências Recentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Center(child: Text('Gráfico de Tendências (Placeholder)')),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Entradas Recentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: BlocBuilder<HealthBloc, HealthState>(
                builder: (context, state) {
                  if (state is HealthLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is HealthEntriesLoaded) {
                    if (state.entries.isEmpty) {
                      return const Center(child: Text('Nenhuma entrada de saúde registrada.'));
                    }
                    return ListView.builder(
                      itemCount: state.entries.length,
                      itemBuilder: (context, index) {
                        final entry = state.entries[index];
                        final formattedDate = DateFormat('dd/MM/yyyy').format(entry.date);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(entry.symptoms),
                            subtitle: Text('${entry.severity} - $formattedDate'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {},
                          ),
                        );
                      },
                    );
                  } else if (state is HealthError) {
                    return Center(child: Text('Erro ao carregar: ${state.message}'));
                  }
                  return const Center(child: Text('Ainda não há dados.'));
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed('/add-health-entry');
        },
        label: const Text('Registrar Entrada'),
        icon: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
