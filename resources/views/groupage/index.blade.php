<x-layouts.app title="Dashboard">
    <div class="flex h-full w-full flex-1 flex-col gap-4 rounded-xl">
        <div class="grid auto-rows-min gap-4 md:grid-cols-3">
            <div class="relative overflow-hidden rounded-xl border border-neutral-200 dark:border-neutral-700">
                <div class="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-2 bg-white px-4 py-10 sm:px-6 xl:px-8">
                    <dt class="text-sm/6 font-medium text-gray-500">Revenue</dt>
                    <dd class="text-xs font-medium text-gray-700">+4.75%</dd>
                    <dd class="w-full flex-none text-3xl/10 font-medium tracking-tight text-gray-900">$405,091.00</dd>
                </div>
            </div>
            <div class="relative overflow-hidden rounded-xl border border-neutral-200 dark:border-neutral-700">
                <div class="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-2 bg-white px-4 py-10 sm:px-6 xl:px-8">
                    <dt class="text-sm/6 font-medium text-gray-500">Overdue invoices</dt>
                    <dd class="text-xs font-medium text-rose-600">+54.02%</dd>
                    <dd class="w-full flex-none text-3xl/10 font-medium tracking-tight text-gray-900">$12,787.00</dd>
                </div>
            </div>
            <div class="relative overflow-hidden rounded-xl border border-neutral-200 dark:border-neutral-700">
                <div class="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-2 bg-white px-4 py-10 sm:px-6 xl:px-8">
                    <dt class="text-sm/6 font-medium text-gray-500">Outstanding invoices</dt>
                    <dd class="text-xs font-medium text-gray-700">-1.39%</dd>
                    <dd class="w-full flex-none text-3xl/10 font-medium tracking-tight text-gray-900">$245,988.00</dd>
                </div>
            </div>
        </div>
        <div class="relative h-full flex-1 overflow-hidden rounded-xl border border-neutral-200 dark:border-neutral-700 py-4">
            <div class="px-4 sm:px-6 lg:px-8">
                <div class="sm:flex sm:items-center">
                    <div class="sm:flex-auto">
                        <h1 class="text-base font-semibold text-gray-900">Groupages</h1>
                        <p class="mt-2 text-sm text-gray-700">Une liste de tous les groupages</p>
                    </div>
                    <div class="mt-4 sm:mt-0 sm:ml-16 sm:flex-none">
                        <flux:button href="{{ route('groupages.create') }}">Nouveau groupage</flux:button>
                    </div>
                </div>
                <div class="mt-8 flow-root">
                    <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
                        <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
                            <table class="min-w-full divide-y divide-gray-300">
                                <thead>
                                <tr>
                                    <th scope="col" class="py-3.5 pr-3 pl-4 text-left text-sm font-semibold text-gray-900 sm:pl-3">Nom</th>
                                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Date debut</th>
                                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Date fin</th>
                                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Statut</th>
                                    <th scope="col" class="relative py-3.5 pr-4 pl-3 sm:pr-3">
                                        <span class="sr-only">Edit</span>
                                    </th>
                                </tr>
                                </thead>
                                <tbody class="bg-white">
                                @foreach($groupages as $groupage)
                                    <tr class="even:bg-gray-50">
                                        <td class="py-4 pr-3 pl-4 text-sm font-medium whitespace-nowrap text-gray-900 sm:pl-3">{{ $groupage->nom }}</td>
                                        <td class="px-3 py-4 text-sm whitespace-nowrap text-gray-500">{{ $groupage->date_debut }}</td>
                                        <td class="px-3 py-4 text-sm whitespace-nowrap text-gray-500">{{ $groupage->date_fin}}</td>
                                        <td class="px-3 py-4 text-sm whitespace-nowrap text-gray-500">{{ $groupage->statut}}</td>
                                        <td class="relative py-4 pr-4 pl-3 text-right text-sm font-medium whitespace-nowrap sm:pr-3">
                                            <a href="{{ route('groupages.show', $groupage) }}" class="text-indigo-600 hover:text-indigo-900">Voir</a>
                                        </td>
                                    </tr>
                                @endforeach

                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

        </div>
    </div>
</x-layouts.app>
