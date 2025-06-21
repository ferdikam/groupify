<div class="space-y-6">
    {{-- Sélection du groupage --}}
    <div class="bg-white rounded-lg border border-gray-200 p-6">
        <h3 class="text-lg font-medium text-gray-900 mb-4">
            Souscripteurs par groupage
        </h3>

        <div class="mb-4">
            <label for="groupage-select" class="block text-sm font-medium text-gray-700 mb-2">
                Sélectionner un groupage
            </label>
            <select
                id="groupage-select"
                wire:model.live="groupageSelectionne"
                class="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 sm:text-sm"
            >
                <option value="">-- Choisir un groupage --</option>
                @foreach($groupages as $groupage)
                    <option value="{{ $groupage->id }}">
                        {{ $groupage->nom }}
                        <span class="text-gray-500">({{ ucfirst($groupage->statut) }})</span>
                    </option>
                @endforeach
            </select>
        </div>

        {{-- Statistiques rapides --}}
        @if($groupageSelectionne && count($souscripteurs) > 0)
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4 mb-6">
                <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
                    <div class="text-sm font-medium text-blue-600">Nombre de souscripteurs</div>
                    <div class="text-2xl font-bold text-blue-900">{{ $this->nombreSouscripteurs }}</div>
                </div>
                <div class="bg-green-50 border border-green-200 rounded-lg p-4">
                    <div class="text-sm font-medium text-green-600">Quantité souscrite</div>
                    <div class="text-2xl font-bold text-green-900">{{ number_format($this->totalQuantite, 0, ',', ' ') }}</div>
                </div>
                <div class="bg-purple-50 border border-purple-200 rounded-lg p-4">
                    <div class="text-sm font-medium text-purple-600">Montant total</div>
                    <div class="text-xl font-bold text-purple-900">{{ number_format($this->totalMontant, 0, ',', ' ') }} FCFA</div>
                </div>
                <div class="bg-orange-50 border border-orange-200 rounded-lg p-4">
                    <div class="text-sm font-medium
                    text-orange-600">Quantité commandée</div>
                    <div class="text-2xl font-bold text-orange-900">{{ number_format($this->moq, 0, ',', ' ') }}</div>
                </div>
                <div class="bg-red-50 border border-red-200 rounded-lg p-4">
                    <div class="text-sm font-medium text-red-600">Surplus</div>
                    <div class="text-2xl font-bold text-red-900">{{ number_format($this->quantiteRestanteCommandee, 0, ',', ' ') }}</div>
                </div>
                <div class="bg-indigo-50 border border-indigo-200 rounded-lg p-4">
                    <div class="text-sm font-medium text-indigo-600">Objectif atteint</div>
                    <div class="text-xl font-bold text-indigo-900">
                        {{ $this->pourcentageObjectif }}%
                        @if($this->objectifAtteint)
                            <span class="text-sm text-green-600">✅</span>
                        @else
                            <span class="text-sm text-red-600">⏳</span>
                        @endif
                    </div>
                </div>
            </div>

            {{-- Barre de progression pour l'objectif --}}
            <div class="mb-6 bg-white border border-gray-200 rounded-lg p-4">
                <div class="flex justify-between items-center mb-2">
                    <span class="text-sm font-medium text-gray-700">Progression vers l'objectif MOQ</span>
                    <span class="text-sm text-gray-500">{{ $this->totalQuantite }} / {{ $this->moq }}</span>
                </div>
                <div class="w-full bg-gray-200 rounded-full h-3">
                    <div class="h-3 rounded-full transition-all duration-300 {{ $this->objectifAtteint ? 'bg-green-500' : 'bg-blue-500' }}"
                         style="width: {{ min(100, $this->pourcentageObjectif) }}%"></div>
                </div>
                <div class="mt-2 text-xs text-gray-600">
                    @if($this->objectifAtteint)
                        🎉 Objectif atteint ! Dépassement de {{ $this->totalQuantite - $this->moq }} unité(s).
                    @else
                        📍 Il reste {{ $this->quantiteRestanteCommandee }} unité(s) pour atteindre l'objectif MOQ.
                    @endif
                </div>
            </div>
        @endif
    </div>

    {{-- Liste des souscripteurs --}}
    @if($groupageSelectionne)
        <div class="bg-white rounded-lg border border-gray-200">
            @if(count($souscripteurs) > 0)
                <div class="px-6 py-4 border-b border-gray-200">
                    <h4 class="text-md font-medium text-gray-900">
                        Liste des souscripteurs ({{ count($souscripteurs) }})
                    </h4>
                </div>

                <div class="overflow-hidden">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Client
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Contact
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    N° Souscription
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Quantité
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Prix unitaire
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Sous-total
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Statut
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Date
                                </th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            @foreach($souscripteurs as $souscripteur)
                                <tr class="hover:bg-gray-50">
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div class="text-sm font-medium text-gray-900">
                                            {{ $souscripteur['client_nom'] }} {{ $souscripteur['client_prenoms'] }}
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div class="text-sm text-gray-900">{{ $souscripteur['client_telephone'] }}</div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div class="text-sm text-gray-900 font-mono">
                                            {{ $souscripteur['numero_souscription'] }}
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div class="text-sm font-semibold text-blue-600">
                                            {{ number_format($souscripteur['quantite'], 0, ',', ' ') }}
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div class="text-sm text-gray-900">
                                            {{ number_format($souscripteur['prix_unitaire'], 0, ',', ' ') }} FCFA
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div class="text-sm font-semibold text-green-600">
                                            {{ number_format($souscripteur['sous_total'], 0, ',', ' ') }} FCFA
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <span class="inline-flex px-2 py-1 text-xs font-semibold rounded-full
                                            @switch($souscripteur['statut_souscription'])
                                                @case('en_attente')
                                                    bg-yellow-100 text-yellow-800
                                                    @break
                                                @case('confirmee')
                                                    bg-blue-100 text-blue-800
                                                    @break
                                                @case('payee')
                                                    bg-green-100 text-green-800
                                                    @break
                                                @case('annulee')
                                                    bg-red-100 text-red-800
                                                    @break
                                                @default
                                                    bg-gray-100 text-gray-800
                                            @endswitch
                                        ">
                                            {{ ucfirst(str_replace('_', ' ', $souscripteur['statut_souscription'])) }}
                                        </span>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div class="text-sm text-gray-500">
                                            {{ \Carbon\Carbon::parse($souscripteur['date_souscription'])->format('d/m/Y') }}
                                        </div>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>

                {{-- Résumé en bas --}}
                <div class="px-6 py-4 bg-gray-50 border-t border-gray-200">
                    <div class="flex justify-between items-center text-sm">
                        <span class="text-gray-600">
                            Total : {{ count($souscripteurs) }} souscripteur(s)
                        </span>
                        <div class="flex space-x-4">
                            <span class="font-medium text-blue-600">
                                Quantité : {{ number_format($this->totalQuantite, 0, ',', ' ') }}
                            </span>
                            <span class="font-medium text-green-600">
                                Montant : {{ number_format($this->totalMontant, 0, ',', ' ') }} FCFA
                            </span>
                        </div>
                    </div>
                </div>
            @else
                <div class="px-6 py-12 text-center">
                    {{--<div class="text-gray-400 mb-2">
                        <svg class="mx-auto h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                                  d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0z" />
                        </svg>
                    </div>--}}
                    <h3 class="text-sm font-medium text-gray-900 mb-1">Aucun souscripteur</h3>
                    <p class="text-sm text-gray-500">
                        Ce produit n'a pas encore de souscripteurs pour le groupage sélectionné.
                    </p>
                </div>
            @endif
        </div>
    @else
        <div class="bg-white rounded-lg border border-gray-200 px-6 py-12">
            <div class="text-center text-gray-500">
                <svg class="mx-auto h-12 w-12 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                          d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                </svg>
                <p class="text-sm">Sélectionnez un groupage pour voir les souscripteurs</p>
            </div>
        </div>
    @endif
</div>
