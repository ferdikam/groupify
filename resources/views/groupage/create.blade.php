<x-layouts.app title="Dashboard">
    <div class="flex h-full w-full flex-1 flex-col gap-4 rounded-xl">

        <div class="relative h-full flex-1 overflow-hidden rounded-xl border border-neutral-200 dark:border-neutral-700 py-4">
            <div class="px-4 sm:px-6 lg:px-8">
                <div class="sm:flex sm:items-center">
                    <div class="sm:flex-auto">
                        <h1 class="text-base font-semibold text-gray-900">Groupages</h1>
                        <p class="mt-2 text-sm text-gray-700">Nouveau</p>
                    </div>
                    <div class="mt-4 sm:mt-0 sm:ml-16 sm:flex-none">

                    </div>
                </div>
                <div class="mt-8 flow-root">
                    <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
                        <div class="w-1/2 mx-10">
                            <form action="{{ route('groupages.store')  }}" method="POST">
                                @csrf
                                <div class="space-y-6">
                                    <div>
                                        <x-label for="nom" :value="__('Nom groupage')" />
                                        <x-text-input id="nom" class="block mt-1 w-full" type="text" name="nom" :value="old('nom')" required autofocus autocomplete="nom" />
                                    </div>
                                    <div>
                                        <x-label for="date_debut" :value="__('Date début')" />
                                        <x-text-input id="date_debut" class="block mt-1 w-full" type="date" name="date_debut" :value="old('date_debut')" required autofocus autocomplete="nom" />
                                    </div>

                                    <div>
                                        <x-label for="date_fin" :value="__('Date Fin')" />
                                        <x-text-input id="date_fin" class="block mt-1 w-full" type="date" name="date_fin" :value="old('date_fin')" required autofocus autocomplete="nom" />
                                    </div>

                                    <div>
                                        <x-label for="date_fin" :value="__('Date Fin')" />
                                        <div class="mt-2 grid grid-cols-1">
                                            <select id="produit_id" name="produit_id" autocomplete="produit_id" class="col-start-1 row-start-1 w-full appearance-none rounded-md bg-white py-1.5 pr-8 pl-3 text-base text-gray-900 outline-1 -outline-offset-1 outline-gray-300 focus:outline-2 focus:-outline-offset-2 focus:outline-indigo-600 sm:text-sm/6">
                                                <option value="">Selectionner un produit</option>
                                                @foreach($produits as $produit)
                                                    <option value="{{ $produit->id }}">{{ $produit->nom }}</option>
                                                @endforeach
                                            </select>
                                            <svg class="pointer-events-none col-start-1 row-start-1 mr-2 size-5 self-center justify-self-end text-gray-500 sm:size-4" viewBox="0 0 16 16" fill="currentColor" aria-hidden="true" data-slot="icon">
                                                <path fill-rule="evenodd" d="M4.22 6.22a.75.75 0 0 1 1.06 0L8 8.94l2.72-2.72a.75.75 0 1 1 1.06 1.06l-3.25 3.25a.75.75 0 0 1-1.06 0L4.22 7.28a.75.75 0 0 1 0-1.06Z" clip-rule="evenodd" />
                                            </svg>
                                        </div>
                                    </div>

                                    <div>
                                        <label for="description" class="block text-sm/6 font-medium text-gray-900">Description</label>
                                        <div class="mt-2">
                                            <textarea name="description" id="description" rows="3" class="block w-full rounded-md bg-white px-3 py-1.5 text-base text-gray-900 outline-1 -outline-offset-1 outline-gray-300 placeholder:text-gray-400 focus:outline-2 focus:-outline-offset-2 focus:outline-indigo-600 sm:text-sm/6"></textarea>
                                        </div>
                                    </div>

                                </div>

                                <div class="mt-6 flex items-center justify-end gap-x-6">
                                    <button type="button" class="text-sm/6 font-semibold text-gray-900">Cancel</button>
                                    <button type="submit" class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-xs hover:bg-indigo-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">Save</button>
                                </div>
                            </form>

                        </div>

                    </div>
                </div>
            </div>

        </div>
    </div>
</x-layouts.app>
